# 🎬 電影人 (Movie People)

「電影人」是一款為台灣影迷量身打造的現代化電影時刻表與社群回報 App。提供全台最即時的電影上映資訊、影城時刻表，並結合了獨家的「特典狀態回報」與「電影短評」功能，讓影迷在觀影前後都能獲得最佳體驗。

---

## 🌟 核心功能 (Features)

### 1. 即時電影與時刻表資訊 (Real-time Movie Data)
*   **現正上映與即將上映**：即時抓取台灣各大院線（開眼電影網）資料，掌握最新電影情報。
*   **全台影城時刻表**：支援全台各大影城（威秀、秀泰、國賓等）的時刻表查詢，並以「廳別與版本（IMAX、4DX、數位等）」進行智慧分組。
*   **直接訂票跳轉**：時刻表整合外部訂票連結（如 EZDing 或影城官網），點擊場次即可一鍵前往訂票。

### 2. 📍 智慧定位與距離排序 (Location-based Sorting)
*   整合 GPS 定位服務，自動計算使用者與全台各影城的距離，並優先顯示距離最近的電影院。

### 3. 🎁 特典即時回報系統 (Bonus Reporting System)
*   **依廳別區分**：電影特典常常依照版本（IMAX、一般數位）發放。系統支援精確到「廳別/格式」的特典狀態回報。
*   **社群即時同步**：透過 Firebase Realtime Database，使用者回報的「有/無特典」狀態會即時更新給所有正在查看該影城時刻表的人。
*   **歷史回報紀錄**：提供完整的特典回報歷史時間線，讓使用者判斷特典庫存趨勢。

### 4. ⭐ 社群評分與十字短評 (Community Ratings & Comments)
*   觀影後可以為電影留下評分（1~5 顆星）以及精煉的「十字短評」。
*   系統採用 Firebase Transaction 處理高併發情境，確保電影總評分與評分人數的資料一致性。

### 5. 🔔 上映推播提醒 (Release Reminders)
*   對於「即將上映」的電影，提供一鍵加入推播提醒的功能，讓影迷不再錯過首映日。

### 6. 👤 社交登入整合 (Social Login)
*   支援 Google 與 Facebook 快捷登入，無縫同步使用者的評分與特典回報紀錄。

---

## 🛠 技術堆疊 (Tech Stack)

### 前端框架與語言
*   **[Flutter](https://flutter.dev/) & Dart**：使用跨平台框架打造高效能、流暢的雙平台應用程式。

### 狀態管理與路由
*   **[flutter_bloc](https://pub.dev/packages/flutter_bloc)**：專案的核心狀態管理。採用事件驅動的 BLoC 模式，將 UI 與業務邏輯完美分離（包含 `MovieBloc`, `CinemaBloc`, `AuthBloc`, `ShowtimeBloc`）。
*   **[GetX](https://pub.dev/packages/get)**：用於輕量級的路由跳轉、對話框 (Dialog)、底部彈窗 (BottomSheet) 以及 Snackbar 的快速呼叫，提升開發效率與動畫流暢度。

### 後端與雲端服務
*   **[Firebase Authentication](https://firebase.google.com/docs/auth)**：處理 Google 與 Facebook 的 OAuth 授權與使用者管理。
*   **[Firebase Realtime Database](https://firebase.google.com/docs/database)**：作為主要資料庫，負責處理高即時性需求的「特典狀態」與「評分系統」，並透過 Stream 提供 UI 的即時刷新。

### 核心功能套件
*   **Web Scraping (`http` + `html`)**：由於台灣電影資訊缺乏統一 API，專案內建強大的爬蟲引擎 (`AtmoviesService`)，能解析 HTML 結構並提取電影與時刻表資訊。
*   **[geolocator](https://pub.dev/packages/geolocator)**：取得設備的 GPS 座標並計算影城距離。
*   **[url_launcher](https://pub.dev/packages/url_launcher)**：處理外部連結的跳轉（訂票頁面、預告片 YouTube 連結等）。
*   **[cached_network_image](https://pub.dev/packages/cached_network_image)**：提供電影海報與劇照的網路圖片快取機制，大幅節省頻寬並提升載入速度。
*   **[shimmer](https://pub.dev/packages/shimmer)**：提供骨架屏（Skeleton Loading）動畫，在資料抓取時維持高質感的 UI 體驗。
*   **[package_info_plus](https://pub.dev/packages/package_info_plus)**：動態讀取並顯示 App 的版本號與 Build Number，方便發布管理。

---

## 🏗 專案架構 (Architecture)

專案採用 **Clean Architecture (簡化版)** 的設計理念，確保各層職責分明：

```text
lib/
├── main.dart                 # 應用程式進入點，初始化 Firebase 與全局 BlocProviders
├── bloc/                     # 狀態管理層 (State Management)
│   ├── auth_bloc.dart        # 處理登入、登出、身分狀態
│   ├── movie_bloc.dart       # 處理現正上映、即將上映電影列表狀態
│   ├── cinema_bloc.dart      # 處理影城列表與定位排序狀態
│   └── showtime_bloc.dart    # 處理單一電影的場次與訂票資訊
├── models/                   # 資料模型層 (Data Models)
│   ├── movie.dart            # 電影實體 (包含標題、海報、評分、簡介)
│   ├── cinema.dart           # 影城實體 (包含座標、地址)
│   ├── showtime.dart         # 場次實體 (包含時間、廳別、語系、訂票連結)
│   ├── bonus_report.dart     # 特典回報紀錄實體
│   └── rating_entry.dart     # 評分與短評實體
├── pages/                    # 視圖層 (UI/Views)
│   ├── splash_page.dart      # 啟動畫面
│   ├── movie_list_page.dart  # 首頁：現正上映列表與抽屜選單
│   ├── movie_detail_page.dart# 電影詳細資訊、預告片與評分入口
│   ├── cinema_list_page.dart # 選擇影城與特典回報介面
│   └── showtime_page.dart    # 最終的時刻表與訂票跳轉介面
├── services/                 # 業務邏輯與外部 API 層 (Services/Repositories)
│   ├── atmovies_service.dart # 核心爬蟲引擎 (抓取電影與場次)
│   ├── bonus_service.dart    # Firebase 互動：處理特典巢狀資料與即時 Stream
│   ├── rating_service.dart   # Firebase 互動：處理 Transaction 與評分上傳
│   ├── auth_service.dart     # OAuth 與登入業務邏輯
│   └── location_service.dart # GPS 定位與距離計算
└── theme/                    # 視覺設計系統 (Design System)
    └── app_theme.dart        # 定義全局顏色、漸層、字體與組件樣式
```

