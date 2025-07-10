
# 支付宝第三方登录接入指南 (Vue + Spring Boot 实现)

## 1. 方案概述

本文档详细阐述了基于 **Vue.js (前端)** 和 **Spring Boot (后端)** 技术栈，实现支付宝第三方授权登录的完整流程。该流程遵循 OAuth 2.0 的授权码模式（Authorization Code），用户通过支付宝App授权后，应用即可安全地获取用户信息并完成自动注册或登录。

### 核心流程

1.  **前端发起**：用户在Vue应用中点击“支付宝登录”按钮。
2.  **跳转授权**：前端重定向到支付宝的官方授权页面。
3.  **用户授权**：用户在支付宝页面确认授权。
4.  **后端回调**：支付宝携带 `auth_code` 重定向到 Spring Boot 后端指定的 `redirect_uri`。
5.  **令牌交换**：后端使用 `auth_code` 向支付宝换取 `access_token`。
6.  **获取信息**：后端使用 `access_token` 获取用户的支付宝公开信息（昵称、头像等）。
7.  **业务处理**：后端根据支付宝用户信息，查询本地数据库。如果用户不存在，则创建新用户；如果存在，则直接登录。无论哪种情况，都生成一个应用自身的 JWT `token`。
8.  **前端接收**：后端携带 JWT `token` 重定向回 Vue 应用的特定回调页面。
9.  **完成登录**：Vue应用获取 `token`，保存到本地存储（localStorage），并更新用户状态，完成整个登录闭环。

---

## 2. 后端实现 (Spring Boot)

### 2.1. 依赖与配置

首先，确保 `pom.xml` 中已引入支付宝官方SDK：

```xml
<dependency>
    <groupId>com.alipay.sdk</groupId>
    <artifactId>alipay-sdk-java</artifactId>
    <version>4.38.100.ALL</version> <!-- 请使用最新版本 -->
</dependency>
```

在 `application.properties` 中配置支付宝沙箱或生产环境的核心参数：

```properties
# alipay sandbox
alipay.app-id=2021000148677978
alipay.private-key=MIIEvg... (你的应用私钥)
alipay.public-key=MIIBI... (你的支付宝公钥)
alipay.gateway-url=[https://openapi-sandbox.dl.alipaydev.com/gateway.do](https://openapi-sandbox.dl.alipaydev.com/gateway.do)
alipay.redirect-uri=http://localhost:8080/api/alipay/callback
alipay.sign-type=RSA2
```

### 2.2. 编写回调接口

`AlipayController.java` 是处理支付宝回调的核心。它负责接收 `auth_code` 并完成后续所有服务端操作。

```java
package csu.web.credit_bank.controller;

import com.alipay.api.AlipayClient;
import com.alipay.api.request.AlipaySystemOauthTokenRequest;
import com.alipay.api.request.AlipayUserInfoShareRequest;
import com.alipay.api.response.AlipaySystemOauthTokenResponse;
import com.alipay.api.response.AlipayUserInfoShareResponse;
import csu.web.credit_bank.service.UsersService;
import csu.web.credit_bank.utils.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
@RequestMapping("/api/alipay")
public class AlipayController {

    @Autowired
    private AlipayClient alipayClient;

    @Autowired
    private UsersService usersService;

    private final String frontendUrl = "http://localhost:3000"; // 前端应用地址

    @GetMapping("/callback")
    public void alipayCallback(@RequestParam("auth_code") String authCode, HttpServletResponse httpResponse) throws IOException {
        String token = null;
        try {
            // 1. 使用 auth_code 换取 access_token
            AlipaySystemOauthTokenRequest tokenRequest = new AlipaySystemOauthTokenRequest();
            tokenRequest.setGrantType("authorization_code");
            tokenRequest.setCode(authCode);
            AlipaySystemOauthTokenResponse tokenResponse = alipayClient.execute(tokenRequest);
            if (!tokenResponse.isSuccess()) throw new RuntimeException("Failed to exchange token");
            
            String accessToken = tokenResponse.getAccessToken();

            // 2. 使用 access_token 获取用户信息
            AlipayUserInfoShareRequest userInfoRequest = new AlipayUserInfoShareRequest();
            AlipayUserInfoShareResponse userInfoResponse = alipayClient.execute(userInfoRequest, accessToken);
            if (!userInfoResponse.isSuccess()) throw new RuntimeException("Failed to get user info");

            // 3. 调用业务层，使用支付宝信息进行登录或注册，并获取应用自身的JWT
            Result result = usersService.loginOrRegisterByAlipay(
                    userInfoResponse.getEmail(),
                    userInfoResponse.getNickName(),
                    userInfoResponse.getAvatar()
            );

            if (result.getCode() == StatusCode.SUCCESS.getCode()) {
                Map<String, Object> data = (Map<String, Object>) result.getData();
                token = (String) data.get("token");
            } else {
                throw new RuntimeException(result.getMsg());
            }
        } catch (Exception e) {
            // 异常处理，重定向到前端错误页
            e.printStackTrace();
            String errorMessage = URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8);
            httpResponse.sendRedirect(frontendUrl + "/login/error?msg=" + errorMessage);
            return;
        }

        // 4. 成功后，携带JWT重定向回前端的回调页面
        httpResponse.sendRedirect(frontendUrl + "/login/callback?token=" + token);
    }
}
```

## 3. 前端实现 (Vue.js)

### 3.1. 发起登录请求

在 `Header.vue` (或任何登录组件) 中，创建一个方法来构建支付宝授权URL并跳转。

```vue
<template>
  <!-- ... -->
  <div class="third-party-login">
    <button @click="handleAlipayLogin" class="alipay-btn">
      <img src="[https://cdn.simpleicons.org/alipay/1677FF](https://cdn.simpleicons.org/alipay/1677FF)" alt="alipay logo" class="alipay-icon"/>
      支付宝
    </button>
  </div>
  <!-- ... -->
</template>

<script setup>
// ...
// 支付宝登录
const handleAlipayLogin = () => {
  const APP_ID = '2021000148677978'; // 与后端配置一致的APP ID
  // 注意：此处的 REDIRECT_URI 是后端的接口地址
  const REDIRECT_URI = 'http://localhost:8080/api/alipay/callback'; 
  const encodedRedirectUri = encodeURIComponent(REDIRECT_URI);
  
  // 构建授权URL
  const authUrl = `https://openauth-sandbox.dl.alipaydev.com/oauth2/publicAppAuthorize.htm?app_id=${APP_ID}&scope=auth_user&redirect_uri=${encodedRedirectUri}`;
  
  // 跳转到支付宝授权页
  window.location.href = authUrl;
};
// ...
</script>
```

### 3.2. 处理最终回调

创建一个专门的页面组件 `LoginCallback.vue`，用于接收后端重定向回来的 `token` 并完成登录。

```vue
<template>
  <div class="loading-container">
    <div class="spinner"></div>
    <p>正在通过支付宝安全登录，请稍候...</p>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { tokenManager } from '@/utils/token';
import { userManager } from '@/utils/user';
import { userServie } from '@/services/user_service';

onMounted(async () => {
  const route = useRoute();

  // 从 URL 的查询参数中获取后端传回的 token
  const token = route.query.token;

  if (token && typeof token === 'string') {
    try {
      // 1. 将 Token 保存到 localStorage
      tokenManager.setToken(token);

      // 2. (可选但推荐)调用后端接口，根据新token获取完整的用户信息
      userServie.getMyInfo((res) => {
        if (res && res.code === 1000) {
          // 3. 保存用户信息到 localStorage
          userManager.setUserInfo(res.data.user, res.data.student, res.data.teacher);

          // 4. 所有信息都保存完毕后，再跳转到首页并刷新
          window.location.href = '/';
        } else {
          console.error('获取用户信息失败:', res.msg);
          window.location.href = '/?error=user_info_failed';
        }
      });

    } catch (error) {
      console.error('处理Token或获取用户信息时出错:', error);
      window.location.href = '/?error=processing_failed';
    }

  } else {
    console.error('未在回调URL中找到Token，授权可能已失败。');
    window.location.href = '/?error=alipay_auth_failed';
  }
});
</script>
```