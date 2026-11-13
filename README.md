# rifa-dev-env

紅火蟻科技（RiFA Technology）的開發環境一鍵建置腳本。

所有專案（A、C、H…）都以 **MSYS2 UCRT64 bash** 作為唯一的執行環境（DEC-013）。開發用的電腦不固定，所以換新電腦時，只要執行一次這裡的腳本就能把環境建好。

> 本 repo 不含任何密鑰或個人資料。`scripts/pg-dev.sh` 裡的帳號密碼只供本機開發使用。

---

## 新電腦：3 個步驟

**1. 在 Windows PowerShell 執行**（MSYS2、套件、環境變數會一次處理完）

```powershell
irm https://raw.githubusercontent.com/aikotoba883/rifa-dev-env/main/bootstrap.ps1 | iex
```

上面這行需要 repo 是 public。如果 repo 是 private，先從 GitHub 下載 zip 並解壓縮，再執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

**2. 把 SSH 公鑰加到 GitHub**

腳本會印出 `~/.ssh/id_ed25519.pub`，把內容貼到 <https://github.com/settings/keys>。

**3. 重開終端機與 Claude Code**，然後在「MSYS2 UCRT64」shell 裡確認：

```bash
cd ~/ZeNX/redant-dev-env && ./verify.sh
```

所有工具都顯示 `[ OK ]` 就完成了。

---

## 已經有 MSYS2 的電腦

```bash
cd ~/ZeNX/redant-dev-env
git pull
./setup.sh          # 可以重複執行，只會補上缺少的項目
```

---

## 檔案說明

| 檔案 | 用途 |
|---|---|
| `bootstrap.ps1` | Windows 端的入口：安裝 MSYS2、跑兩輪 `pacman -Syu`、設定使用者環境變數、clone 本 repo，最後呼叫 `setup.sh` |
| `setup.sh` | UCRT64 端：安裝套件、設定 git、產生 SSH key、安裝 Claude Code CLI、執行 `verify.sh` |
| `packages-ucrt64.txt` | pacman 套件清單。要新增工具時**只改這個檔案** |
| `verify.sh` | 檢查並列出所有工具的版本；有缺少時回傳 1 |
| `scripts/pg-dev.sh` | 本機 PostgreSQL：`init` / `start` / `stop` / `status` / `psql` |

### bootstrap.ps1 設定的使用者環境變數

| 變數 | 值 | 原因 |
|---|---|---|
| `CLAUDE_CODE_GIT_BASH_PATH` | `C:\msys64\usr\bin\bash.exe` | 讓 Claude Code 的 Bash 工具改用 MSYS2，不用 Git for Windows 的 bash，這樣才看得到 UCRT64 的工具鏈 |
| `MSYSTEM` | `UCRT64` | 讓 bash 以 UCRT64 環境啟動 |
| `CHERE_INVOKING` | `1` | 讓 login shell 保留目前的工作目錄 |

---

## 本機 PostgreSQL（Q1，DEC-014）

Q1 不使用 Docker，改用 MSYS2 原生的 PostgreSQL。帳號密碼和實作指南裡的 `docker-compose.yml` 相同，Q2 改用 Docker 時連線字串不用改：

```
postgres://redant:redant_dev@localhost:5432/redant_erp
```

```bash
scripts/pg-dev.sh init      # 第一次使用：建立資料目錄與 redant_erp 資料庫，並啟動
scripts/pg-dev.sh start     # 每次開工
scripts/pg-dev.sh psql -c 'select 1'
scripts/pg-dev.sh stop      # 收工
```

資料存放在 `~/.local/share/redant-pg/`。這個目錄不會跟著換電腦，需要搬資料時請用 `pg_dump`。

---

## 已知限制

- **MinGW GCC 不支援 AddressSanitizer**（OPEN-012）：UBSan 可以用 `-fsanitize=undefined -fsanitize-trap`。ASan 的做法會在 M1 第 4 週前決定，提案是在 GitHub Actions 加一個 Linux job 跑 ASan。
- SDL3 與 Catch2 **不透過 pacman 安裝**，各專案以 CMake `FetchContent` 釘選版本，確保換電腦也能重現相同的建置結果。
- `MSYSTEM` 設成使用者環境變數後，會影響所有從 Windows 啟動的 MSYS2 類 shell。如果 Git for Windows 的 bash 出現異常，把這個變數移除，改用 MSYS2 提供的「UCRT64」捷徑啟動即可。
- `bootstrap.ps1` 沒有在全新的電腦上完整測試過，第一次在新電腦上使用時請留意輸出訊息。
