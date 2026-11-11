# RustDesk ID & 服务器修改工具（中文界面版）v4

图形化修改 RustDesk 本地客户端 ID / 中继(Private)服务器 / 访问 Key / 配置字符串 / 永久密码 的批处理脚本，是原作者 Abdullah ERTURK 项目的中文本地化版本。

原始项目: https://github.com/abdullah-erturk/RustDesk-ID-Server-Changer

RustDesk 官方: https://github.com/rustdesk/rustdesk

---

## 关于许可证（请务必阅读）

原作者仓库的 README.md / .bat / preview.jpg 三个文件中 **没有附带 LICENSE 授权文件**。
按默认规则，未声明许可的作品属于「保留所有权利」，因此：

- 本仓库不擅自替原作者添加任何开源许可证；
- 保留原作者 Abdullah ERTURK 的全部署名与版权；本仓库仅对界面文字做中文本地化，功能逻辑与原版一致；
- 二次分发 / 使用请遵循上游项目的许可约定；如需明确的开源许可，建议先向上游作者确认。

如果你只是自己或团队内部使用，以上不影响正常使用。

---

## 功能一览

| 编号 | 功能 |
| :--- | :--- |
| 1 | 用计算机名设置 RustDesk ID（机房 / 批量部署场景，免重启） |
| 2 | 用 9 位随机数字设置 ID（与 RustDesk 原生格式一致，各版本通用） |
| 3 | 自定义 ID（最小长度按系统自动判定：Win10/11 为 6，Win7/8 为 7，Server 为 8 字符） |
| 4 | 切换到 Public 公共服务器（自动安全备份当前私有服务器配置） |
| 5 | 切换到 Private 私有服务器（恢复之前备份的配置） |
| 6 | 新建私有服务器（输入 IP/Host 与 Key） |
| 7 | 导入完整配置字符串（RustDesk 导出的 ID/Relay/API + Key 一次性导入） |
| 8 | 设置永久访问密码（不少于 6 位） |
| 9 | 撤销上一次 ID 修改（用修改前的备份回滚） |
| P | 清除设置锁 PIN（无需知道旧 PIN） |
| 0 | 删除私有服务器备份文件 |

其他特性:
- 菜单顶部实时显示当前 ID 与活动服务器（Public/Private + 地址）；
- 每步操作后用 rustdesk.exe --get-id 自动校验，并写入带时间戳的 RustDesk_Changer.log；
- 通过注册表动态检测安装路径，兼容 portable 便携版；
- 修改配置时停掉全部 RustDesk 进程，解决 Windows Server / RDP 多会话「ID 改完又回退」的问题，改完自动重启用户会话 GUI；
- 中文界面 + GBK(chcp 936) 代码页，命令行不乱码。

---

## 使用方法

1. 下载 RustDesk_Changer_中文版.bat；
2. 右键「以管理员身份运行」（脚本也会自动尝试提权）；
3. 按菜单编号选择操作；
4. 完成后重启 / 让脚本自动重启 RustDesk 即生效。

---

## 文件清单

- RustDesk_ID_Server_Changer_中文版.bat —— 脚本本体（GBK 编码保存，请勿转成 UTF-8，否则中文乱码）
- README.md —— 本说明（UTF-8）

---

## 免责声明

本脚本仅修改本机 RustDesk 的连接配置，请用于连接你自有或已获授权的服务器。因使用本工具造成的任何数据、连接或系统问题，风险自负。

## 致谢

- 原始功能与逻辑：Abdullah ERTURK（https://github.com/abdullah-erturk/RustDesk-ID-Server-Changer）
- 
- RustDesk：https://github.com/rustdesk/rustdesk
