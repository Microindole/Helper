# 支付宝沙箱扫码支付接入指南 (Python Flask 实现)

## 1. 方案概述

本文档基于 **Python Flask** 框架，实现PC端网站的支付宝扫码支付功能。此方案的核心是后端生成一个包含支付信息的URL，并将其转换为二维码展示给用户。前端通过轮询（Polling）机制，定时向后端查询订单状态，以确认支付是否成功。

### 核心流程

1.  **前端请求**：用户在前端页面点击“支付”，前端向后端发起创建订单的请求。
2.  **后端生成订单**：Flask后端接收请求，调用支付宝SDK生成一个支付链接。
3.  **生成二维码**：后端使用 `qrcode` 库将支付链接转换成二维码图片，并以 Base64 字符串的形式返回给前端。
4.  **前端展示**：前端将 Base64 字符串渲染成二维码图片，并开始定时轮询后端的状态查询接口。
5.  **用户扫码**：用户使用手机支付宝App扫描二维码并完成支付。
6.  **异步通知**：支付宝服务器向后端预设的 `notify_url` 发送异步POST请求，通知支付结果。后端验证签名后，更新内部订单状态。
7.  **前端轮询结果**：前端的轮询请求最终从后端获取到“支付成功”的状态，随即执行页面跳转或解锁内容等后续业务逻辑。

---

## 2. 后端实现 (Flask)

### 2.1. 依赖与配置

首先，安装必要的Python库：

```bash
pip install Flask Flask-Cors python-alipay-sdk qrcode pillow
```

在 `app.py` 中，定义支付宝配置和初始化客户端。密钥文件建议存放在安全路径。

```python
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from alipay import AliPay
import qrcode
import base64
from io import BytesIO

app = Flask(__name__)
CORS(app)

# 用于存储订单状态的内存字典（生产环境应使用数据库）
payment_statuses = {}

# 公网可访问的域名，用于接收异步通知
PUBLIC_DOMAIN = "http://your-public-domain.com" 

# 支付宝沙箱配置
ALIPAY_CONFIG = {
    'APP_ID': 'your APPID',
    'APP_PRIVATE_KEY_PATH': 'keys/app_private_key.pem',
    'ALIPAY_PUBLIC_KEY_PATH': 'keys/alipay_public_key.pem',
    'SIGN_TYPE': 'RSA2',
    'DEBUG': False, # 生产环境设为 False
    'GATEWAY': 'https://openapi-sandbox.dl.alipaydev.com/gateway.do'
}

def get_alipay_client():
    # 从文件读取密钥字符串
    with open(ALIPAY_CONFIG['APP_PRIVATE_KEY_PATH']) as f:
        app_private_key_string = f.read()
    with open(ALIPAY_CONFIG['ALIPAY_PUBLIC_KEY_PATH']) as f:
        alipay_public_key_string = f.read()

    alipay = AliPay(
        appid=ALIPAY_CONFIG['APP_ID'],
        app_notify_url=None, # 通知地址在创建订单时单独指定
        app_private_key_string=app_private_key_string,
        alipay_public_key_string=alipay_public_key_string,
        sign_type=ALIPAY_CONFIG['SIGN_TYPE'],
        debug=ALIPAY_CONFIG['DEBUG']
    )
    return alipay
```

### 2.2. 核心API接口

#### a. 创建支付与二维码接口

此接口接收订单信息，返回用于生成二维码的Base64数据。

```python
@app.route('/api/create-payment', methods=['POST'])
def create_payment():
    data = request.get_json()
    out_trade_no = data.get('outTradeNo')
    
    # 初始化订单状态
    payment_statuses[out_trade_no] = "WAIT_BUYER_PAY"

    alipay = get_alipay_client()
    notify_url = PUBLIC_DOMAIN + '/api/payment-notify'
    
    # 使用 PC 网站支付接口 alipay.trade.page.pay
    order_string = alipay.api_alipay_trade_page_pay(
        out_trade_no=out_trade_no,
        total_amount=float(data.get('price')),
        subject=data.get('subject'),
        notify_url=notify_url
    )
    payment_url = ALIPAY_CONFIG['GATEWAY'] + '?' + order_string

    # 使用 qrcode 库将支付URL生成二维码
    img = qrcode.make(payment_url)
    
    # 将二维码图片转为 Base64 字符串
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

    return jsonify({
        "qrCodeBase64": img_str
    })
```

#### b. 异步通知接口

此接口用于接收支付宝的支付结果通知，必须部署在公网可访问的服务器上。

```python
@app.route('/api/payment-notify', methods=['POST'])
def payment_notify():
    data = request.form.to_dict()
    signature = data.pop("sign", None)
    
    alipay = get_alipay_client()
    # 验证签名，确保请求来自支付宝
    success = alipay.verify(data, signature)

    if success and data.get("trade_status") in ("TRADE_SUCCESS", "TRADE_FINISHED"):
        out_trade_no = data.get('out_trade_no')
        # 更新订单状态
        payment_statuses[out_trade_no] = "TRADE_SUCCESS"
        # 此处执行发货、解锁DLC等业务逻辑...
        return "success" # 必须返回纯文本 "success"
    else:
        return "failure"
```

#### c. 状态查询接口

前端通过轮询此接口来获知支付结果。

```python
@app.route('/api/check-payment-status', methods=['GET'])
def check_payment_status():
    out_trade_no = request.args.get('outTradeNo')
    if not out_trade_no:
        return jsonify({"error": "缺少订单号"}), 400
    
    # 从内存（或数据库）中获取订单状态
    status = payment_statuses.get(out_trade_no, "NOT_FOUND")
    
    return jsonify({"trade_status": status})
```

## 3. 前端交互逻辑 (示例)

前端的核心是展示二维码并启动一个定时器来轮询状态。

```js
// 1. 请求创建支付
async function createPayment() {
    const orderDetails = {
        outTradeNo: 'ORDER_' + Date.now(),
        price: '0.01',
        subject: 'My Awesome Product'
    };

    const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderDetails)
    });
    const result = await response.json();

    // 2. 显示二维码
    const qrImage = document.getElementById('qr-code-image');
    qrImage.src = 'data:image/png;base64,' + result.qrCodeBase64;

    // 3. 开始轮询检查状态
    startPolling(orderDetails.outTradeNo);
}

// 4. 轮询函数
function startPolling(outTradeNo) {
    const intervalId = setInterval(async () => {
        const response = await fetch(`/api/check-payment-status?outTradeNo=${outTradeNo}`);
        const result = await response.json();

        if (result.trade_status === 'TRADE_SUCCESS') {
            clearInterval(intervalId); // 停止轮询
            alert('支付成功!');
            // 在这里进行页面跳转或更新UI
            window.location.href = '/payment-success-page';
        }
    }, 3000); // 每3秒查询一次
}

// 页面加载后启动支付流程
createPayment();
```