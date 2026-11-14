# BarkBattery

电量低于阈值时,通过 Bark API 推送通知。设置页在系统「设置」里。
目标:rootful 越狱 iOS 13.x(checkra1n / unc0ver),arm64 / arm64e。

## 环境准备
- 电脑:安装 [Theos](https://theos.dev),`$THEOS/sdks` 里放 iOS 13.x SDK(需包含 PrivateFrameworks/Preferences,否则设置页链接会失败)
- 手机:Cydia/Sileo 安装 OpenSSH、Cydia Substrate(或 Substitute)、PreferenceLoader
- 设置 `export THEOS_DEVICE_IP=手机IP`、`export THEOS_DEVICE_PORT=22`

## 编译安装
```bash
make package install
```
安装后会自动 respring。然后到「设置 → BarkBattery」填 Bark Key,点「发送测试推送」验证通路。

## 修改包名
默认 `com.example.barkbattery`。如需修改,以下位置必须同步:
`control`、`Tweak.x`(PREFS_DOMAIN 与两个通知名)、`Root.plist`(defaults / PostNotification)、
`BBPRootListController.m`(通知名)。

## 调试
```bash
idevicesyslog | grep BarkBattery      # 电脑端
oslog | grep BarkBattery              # 手机端(安装 oslog)
```
日志不会打印 Bark Key。

## 行为说明
- 电量 <= 阈值 且 未充电(或勾选「充电时也推送」)→ 推送一次
- 电量回升到 阈值+5% 或 开始充电 → 重新武装,避免反复推送

## 已知限制
- 息屏深度休眠时 SpringBoard 的网络请求可能延迟。若实测不稳定,可改为独立 LaunchDaemon(IOKit 读电量)
- Bark Key 以明文存在 `/var/mobile/Library/Preferences/com.example.barkbattery.plist`

## 用 GitHub Actions 编译(无需本地 Theos)
1. 新建 GitHub 仓库,把本项目全部文件推上去(含 `.github/workflows/build.yml`)
2. 仓库 → Actions 页,等待 "Build BarkBattery" 跑完(也可手动 Run workflow)
3. 点进该次运行,在 Artifacts 里下载 `BarkBattery-deb`,解压得到 `.deb`
4. 把 `.deb` 传到手机(Filza / scp),用 Filza 点开安装,或 `dpkg -i xxx.deb && killall -9 SpringBoard`
