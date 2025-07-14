# 地图工具箱 (`MapDetailComponent / BaiduMap`) 使用教程

## 1. 简介

`MapDetailComponent` 是一个功能强大的前端UI组件，它以原生JavaScript类的形式封装，旨在为已有的百度地图实例附加一个功能丰富的“地图工具箱”模态框。用户可以通过这个工具箱执行诸如查看实时路况、搜索周边、规划路线、测量距离等一系列高级交互操作。

该组件的设计目标是与现有地图无缝集成，提供统一、直观的用户体验，并将复杂的地图API调用封装成简单的UI交互。

- **组件核心文件**: `map.js`
- **主要交互界面**: 通过点击页面上的“地图工具”按钮触发一个全屏模态框。
- **设计风格**: 现代化、功能分区清晰，支持通过CSS进行深度定制。

## 2. 准备工作与依赖

在你的HTML页面中集成此组件前，请确保已满足以下依赖条件：

1. **引入百度地图GL版JS API**：这是所有功能的基础。请将 `YOUR_BAIDU_MAP_AK` 替换为你自己的密钥。

   ```html
   <script type="text/javascript" src="https://api.map.baidu.com/api?v=1.0&type=webgl&ak=YOUR_BAIDU_MAP_AK"></script>
   ```

2. **引入百度地图测距工具库**：`测量距离` 功能需要此官方扩展库。

   ```html
   <script type="text/javascript" src="https://api.map.baidu.com/library/DistanceTool/1.2/src/DistanceTool_min.js"></script>
   ```

3. **引入本组件的JS文件**：即你提供的 `map.js`。

   ```html
   <script type="text/javascript" src="/path/to/your/map.js"></script>
   ```

4. **提供地图容器**：页面中必须有一个用于挂载地图和工具按钮的 `<div>` 容器，且其 `id` **必须为 `map-container`**。

   ```html
   <div id="map-container" style="width: 100%; height: 500px;"></div>
   ```

5. **(可选) 全局消息提示函数**：组件会尝试调用 `window.showMessage(message, type)` 来显示美观的操作反馈（其中 `type` 为 `'success'` 或 `'error'`）。如果未定义，将回退到 `console.log` 和 `console.error`。你可以自己实现这个函数，例如：

   ```js
   // 示例：使用一个简单的alert作为消息提示
   window.showMessage = function(message, type) {
       const prefix = type === 'success' ? '✅ 成功' : '❌ 错误';
       alert(`${prefix}: ${message}`);
   };
   ```

## 3. 初始化组件

组件通过全局函数 `initMapDetailComponent` 进行初始化。你应该在一个已经创建了地图实例和房源标记点之后调用它。

**函数签名**: `initMapDetailComponent(mapInstance, houseData, marker)`

- `mapInstance` (Object): **必需**。一个已经实例化的 `BMapGL.Map` 对象。
- `houseData` (Object): **必需**。包含房源信息的对象，至少应包含地址信息，用于在工具箱中展示。例如: `{ region: '海淀区', addr: '上地十街10号' }`。
- `marker` (Object): **必需**。代表房源位置的 `BMapGL.Marker` 对象，组件的许多功能（如周边搜索、路线规划终点）都围绕此标记点进行。

**完整示例代码：**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>地图工具箱组件使用示例</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
    <style>
        body, html, #map-container { width: 100%; height: 100%; overflow: hidden; margin: 0; font-family: "Microsoft YaHei"; }
        /* 你需要为 map.js 中的模态框和按钮提供CSS样式 */
    </style>
    <script type="text/javascript" src="https://api.map.baidu.com/api?v=1.0&type=webgl&ak=YOUR_BAIDU_MAP_AK"></script>
    <script type="text/javascript" src="https://api.map.baidu.com/library/DistanceTool/1.2/src/DistanceTool_min.js"></script>
    <script type="text/javascript" src="map.js"></script>
</head>
<body>
    <div id="map-container"></div>

    <script>
        // 1. 创建地图实例
        const map = new BMapGL.Map("map-container");
        const point = new BMapGL.Point(116.307428, 40.057031); // 示例坐标：百度大厦
        map.centerAndZoom(point, 17);
        map.enableScrollWheelZoom(true);

        // 2. 创建房源的主标记点
        const mainMarker = new BMapGL.Marker(point);
        map.addOverlay(mainMarker);

        // 3. 准备房源数据
        const houseInfo = {
            region: '海淀区',
            addr: '上地十街10号'
        };

        // 4. 初始化地图工具箱组件
        // 确保在DOM加载完成后执行
        document.addEventListener('DOMContentLoaded', () => {
            window.initMapDetailComponent(map, houseInfo, mainMarker);
        });
    </script>
</body>
</html>
```

## 4. 功能详解

初始化后，页面上会出现“地图工具”按钮，点击即可打开工具箱。

### 4.1 🎯 基础工具

- **房源位置**: 将地图视图迅速居中并缩放到房源标记点所在的位置 (Zoom Level 17)。
- **实时路况**: 在地图上叠加或移除实时交通状况图层。按钮激活时会添加 `active` 类，便于样式高亮。
- **测量距离**: 激活地图测距功能。激活后，你可以通过在地图上连续点击来测量点与点之间的直线距离。
- **卫星地图**: 在普通的城市地图视图 (`BMAP_NORMAL_MAP`) 和高清卫星影像视图 (`BMAP_SATELLITE_MAP`) 之间进行切换。按钮激活时会添加 `active` 类。

### 4.2 🏪 周边设施 (POI搜索)

点击此区域的任一按钮（如 `地铁站`, `公交站`, `医院` 等），组件将：

1. 以当前房源位置为中心。
2. 在 **2公里** 半径范围内搜索相应的设施 (POI)。
3. 清除上一次的POI搜索结果，并将最新的结果（最多10个）以对应的小图标标记在地图上。
4. 点击这些新的POI标记，会弹出信息窗口显示其名称和地址。

### 4.3 🛣️ 路线规划

此功能可以帮你规划从任意起点到当前房源位置的路线。

1. 在 **“输入起点地址”** 的文本框中输入你的出发点。
2. 点击 **`驾车`**, **`公交`**, 或 **`步行`** 按钮。
3. 组件会自动调用相应的路线规划服务，并在地图上清除其他覆盖物后，绘制出详细的路线方案，同时地图会自动调整视野以包含完整路线。

### 4.4 ℹ️ 地图信息与操作

- **地图信息区**:
  - `缩放级别`: 实时显示当前地图的缩放层级。
  - `中心坐标`: 实时显示地图中心点的经纬度（保留6位小数）。
  - `房源地址`: 显示初始化时传入的 `houseData` 中的地址信息。
- **操作按钮**:
  - `清除标记`: 一键清除所有由工具箱添加的覆盖物，包括**周边设施(POI)标记**、**路线规划图层**和**实时路况图层**。**注意：它不会移除最主要的房源标记点**，并会重新将其添加到地图上。
  - `刷新地图`: 将地图重置到初始状态，执行 `清除标记` 的所有操作，并重新定位到房源位置。

## 5. 组件方法与状态

`MapDetailComponent` 类实例包含以下重要属性和方法：

- `map`: BMapGL.Map 实例。
- `houseData`: 房源信息对象。
- `currentMarker`: 当前房源的核心 `BMapGL.Marker` 实例。
- `isTrafficVisible`: (Boolean) 标记路况图层是否可见。
- `poiMarkers`: (Array) 存储当前显示的POI标记。
- `routeLayer`: 当前路线规划图层实例。
- `showModal()` / `hideModal()`: 控制工具箱的显示与隐藏。
- `setCurrentMarker(marker)`: 用于更新组件内部引用的核心标记点。