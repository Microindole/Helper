# 🚀 如何打造一个引人注目的 GitHub 个人主页 (Profile README)



你好！欢迎阅读本教程。

你是否羡慕过一些开发者的 GitHub 主页看起来非常酷炫，有各种动态的图表和好玩的功能？其实，这些大部分都不是 GitHub 的付费功能，而是通过一个叫做 **“个人资料自述文件 (Profile README)”** 的秘密功能实现的。

本教程将从零开始，手把手带你创建一个既专业又充满个性的 GitHub 个人主页。



## 目录
1.  [基础篇：激活你的 Profile README](#1-基础篇激活你的-profile-readme)
2.  [数据篇：展示你的 GitHub 统计](#2-数据篇展示你的-github-统计)
3.  [美化篇：添加更多“花里胡哨”的有趣功能](#3-美化篇添加更多花里胡哨的有趣功能)
    * [动态打字特效](#动态打字特效)
    * [GitHub 成就奖杯](#github-成就奖杯)
    * [访客计数器](#访客计数器)
    * [贡献图贪吃蛇动画 (进阶)](#贡献图贪-吃蛇动画-进阶)
4.  [布局篇：使用表格创建两栏布局](#4-布局篇使用表格创建两栏布局)
5.  [最终代码示例](#5-最终代码示例)

------



## 1. 基础篇：激活你的 Profile README



这是开启一切的钥匙。方法非常简单：

1. **登录 GitHub**，点击右上角的 `+` 号，选择 **New repository**。
2. **关键一步**：仓库的名称必须和你的 GitHub 用户名**完全一样**。例如，如果你的用户名是 `Microindole`，那么仓库名也必须是 `Microindole`。
3. 创建时，GitHub 会提示你发现了一个秘密！请确保仓库是 **Public (公开)** 的，并勾选 **"Add a README file"**。
4. 创建成功后，这个仓库里的 `README.md` 文件的内容，就会自动显示在你的个人主页顶部了！



## 2. 数据篇：展示你的 GitHub 统计



让别人快速了解你的活跃度和技术栈，动态统计卡片是最好的选择。我们主要使用一个非常流行的开源项目：[GitHub Readme Stats](https://github.com/anuraghazra/github-readme-stats)。

你只需要将下面的 Markdown 代码复制到你的 `README.md` 文件中，并把 `?username=` 后面的 `your_username` **换成你自己的 GitHub 用户名**。



#### a. GitHub 综合统计卡片



显示你的总星星数、提交数、PR数等。

```markdown
<a href="https://github.com/anuraghazra/github-readme-stats">
  <img align="center" src="https://github-readme-stats.vercel.app/api?username=your_username&show_icons=true&theme=radical&rank_icon=github" />
</a>
```

- `theme=` 后面可以更换不同的主题，比如 `dracula`, `onedark` 等。



#### b. 常用语言统计卡片



自动统计你最常使用的编程语言。

```markdown
<a href="https://github.com/anuraghazra/github-readme-stats">
  <img align="center" src="https://github-readme-stats.vercel.app/api/top-langs/?username=your_username&layout=compact&theme=radical&langs_count=10" />
</a>
```

- `langs_count=` 可以控制显示语言的数量。



## 3. 美化篇：添加更多“花里胡哨”的有趣功能



现在，我们来加入一些能让你的主页脱颖而出的有趣功能。



#### 动态打字特效



在主页上模拟打字机效果，可以用来展示你的欢迎语或座右铭。

```markdown
<div align="center">
  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.herokuapp.com?font=JetBrains+Mono&size=20&pause=1500&color=20B2AA&center=true&vCenter=true&width=435&lines=Hi%2C+I'm+Your+Name+%F0%9F%91%8B;A+passionate+developer;Always+learning%2C+always+growing.&repeat=true" alt="Typing SVG" />
  </a>
</div>
```

- 修改 `lines=` 后面的文字，用 `%20` 代表空格，用 `;` 来换行。
- 在链接末尾加上 `&repeat=true` 可以让动画循环播放。



#### GitHub 成就奖杯



将你的 GitHub 成就游戏化，生成不同等级的奖杯。

```markdown
<div align="center">
  <img src="https://github-profile-trophy.vercel.app/?username=your_username&theme=dracula&row=1&column=7&margin-w=15&margin-h=15" alt="Trophies" />
</div>
```

- `username=` 同样需要换成你自己的。



#### 访客计数器



统计有多少人访问了你的主页。

```markdown
<img align="left" src="https://komarev.com/ghpvc/?username=your_username&label=Profile%20views&color=brightgreen&style=flat" alt="Profile views" />
```



#### 贡献图贪吃蛇动画 (进阶)



这是一个非常酷炫的功能，它会根据你过去一年的提交记录，生成一条贪吃蛇动画。但这需要通过 **GitHub Actions** 来自动生成。

第一步：创建 Workflow 文件

在你的个人主页仓库 (your_username/your_username) 中，创建一个新文件，路径必须为 .github/workflows/snake.yml。

第二步：粘贴代码

将下面的代码完整地粘贴到 snake.yml 文件中：

```yaml
name: Generate Snake Animation
on:
  schedule:
    - cron: "0 12 * * *"
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Platane/snk@v3
        with:
          github_user_name: ${{ github.repository_owner }}
          outputs: |
            dist/github-contribution-grid-snake.svg
            dist/github-contribution-grid-snake-dark.svg?palette=github-dark
      - uses: crazy-max/ghaction-github-pages@v3.1.0
        with:
          target_branch: output
          build_dir: dist
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**第三步：配置权限并运行**

1. 进入仓库的 **Settings -> Actions -> General**，将权限设置为 **"Read and write permissions"**。
2. 进入仓库的 **Actions** 标签页，找到 "Generate Snake Animation"，手动运行一次。

第四步：在 README 中引用图片

将下面的代码添加到你的 README.md 中：

```markdown
<div align="center">
  <img src="https://raw.githubusercontent.com/your_username/your_username/output/github-contribution-grid-snake-dark.svg" alt="snake" />
</div>
```



## 4. 布局篇：使用表格创建两栏布局



为了让页面更整洁，我们可以使用 HTML 的 `<table>` 标签创建一个“左文右图”的两栏布局。

```markdown
<table align="center" style="border: none;">
<tr style="border: none;">
<td width="55%" valign="top" style="border: none;">
  </td>
<td width="45%" valign="top" style="border: none;">
  </td>
</tr>
</table>
```



## 5. 最终代码示例



这是一个整合了上述大部分功能的完整示例代码。你可以直接复制，然后修改里面的 `your_username` 和其他个人信息。

```markdown
<div align="center">
  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.herokuapp.com?font=JetBrains+Mono&size=20&pause=1500&color=20B2AA&center=true&vCenter=true&width=435&lines=Hi%2C+I'm+Your+Name+%F0%9F%91%8B;A+passionate+developer;Always+learning%2C+always+growing.&repeat=true" alt="Typing SVG" />
  </a>
</div>

<br>

<table align="center" style="border: none;">
<tr style="border: none;">
<td width="55%" valign="top" style="border: none;">

  ### 你好, 我是 [你的名字] 👋
  
  ### 🛠️ 我的技能栈 (My Skills)
  <p>
    <a href="#"><img src="https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white"/></a>
    <a href="#"><img src="https://img.shields.io/badge/Spring-6DB33F?style=for-the-badge&logo=spring&logoColor=white"/></a>
  </p>

  ### 📫 如何联系我 (Contact Me)
  <p>
    <a href="mailto:your-email@example.com"><img src="https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white" /></a>
  </p>
  <br>
  <img align="left" src="https://komarev.com/ghpvc/?username=your_username&label=Profile%20views&color=brightgreen&style=flat" alt="Profile views" />

</td>
<td width="45%" valign="top" style="border: none;">
  <a href="https://github.com/anuraghazra/github-readme-stats">
    <img align="center" src="https://github-readme-stats.vercel.app/api?username=your_username&show_icons=true&theme=radical&rank_icon=github" />
  </a>
  <br><br>
  <a href="https://github.com/anuraghazra/github-readme-stats">
    <img align="center" src="https://github-readme-stats.vercel.app/api/top-langs/?username=your_username&layout=compact&theme=radical&langs_count=10" />
  </a>
</td>
</tr>
</table>

<div align="center">
  <img src="https://github-profile-trophy.vercel.app/?username=your_username&theme=dracula&row=1&column=7" alt="Trophies" />
</div>

<div align="center">
  <img src="https://raw.githubusercontent.com/your_username/your_username/output/github-contribution-grid-snake-dark.svg" alt="snake" />
</div>
```

------

