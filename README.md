# Polish Notation Demystification – FPGA Lab README

> 在這門 **FPGA** Lab 中，你將設計一顆硬體加速器，能在四種模式下解析並計算 Prefix / Postfix 波蘭表示式，並依規格輸出結果。透過此專案，你會學到 **堆疊運算、排序器設計、RTL 時序管控** 等觀念。:contentReference[oaicite:0]{index=0}

---

## 1. 實驗目標
- **解析**：判斷每筆輸入是運算元或運算子  
- **計算**：支援 `+`, `-`, `*`, `|a+b| ($)` 四種運算  
- **排序**：多組運算結果需依指定方式排序  
- **時序**：每筆 pattern 延遲 ≤ 1000 cycles:contentReference[oaicite:1]{index=1}

---

## 2. I/O 介面

| Signal | Dir | Width | 說明 |
| ------ | --- | ----- | ---- |
| `clk` / `rst_n` | I | 1 | 時脈 / 非同步低態重設 |
| `mode` | I | 2 | 0: Prefix＋降冪排序<br>1: Postfix＋升冪排序<br>2: NPN<br>3: RPN:contentReference[oaicite:2]{index=2} |
| `operator` | I | 1 | 0: `in` 為運算元<br>1: `in` 為運算子:contentReference[oaicite:3]{index=3} |
| `in` | I | 3 | 運算元 0–7；運算子編碼：000:+, 001:-, 010:*, 011:$:contentReference[oaicite:4]{index=4} |
| `in_valid` | I | 1 | 高電位時 `in`/`operator` 有效 |
| `out` | O | 32 (signed) | 運算結果（可能為負） |
| `out_valid` | O | 1 | 高電位時 `out` 有效 |

---

## 3. 四種模式

| Mode | 表示法 | 分組大小 | 排序方式 | `out_valid` 長度 |
| :--: | :----: | :------: | :------: | :--------------: |
| `00` | Prefix | 每 3 token 一組 | **降冪** | = `in_valid` 時間 × 1/3 |
| `01` | Postfix | 每 3 token 一組 | **升冪** | = `in_valid` 時間 × 1/3 |
| `10` | NPN | 整段一次 | — | 1 cycle |
| `11` | RPN | 整段一次 | — | 1 cycle |

> *範例*：Mode 0 連續 6 cycle 輸入可形成兩組 prefix 式子，計算完須先降冪排序再輸出:contentReference[oaicite:5]{index=5}；Mode 3 則僅輸出 1 個結果，`out_valid` 只會拉高 1 cycle:contentReference[oaicite:6]{index=6}。

---

## 4. 主要規格

1. `rst_n` 觸發後所有輸出需歸零  
2. `in_valid` 高時不得同時拉高 `out_valid`  
3. `out_valid` 為 0 時，`out` 必須為 0  
4. **每個 pattern 延遲 ≤ 1000 cycles**:contentReference[oaicite:7]{index=7}  
5. Mode 0/1 時 `out_valid` 長度 = `in_valid` × 1/3；Mode 2/3 時 `out_valid` 只佔 1 cycle:contentReference[oaicite:8]{index=8}
