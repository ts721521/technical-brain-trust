# Theory Change Proposal - Antigravity

**Author**: Antigravity
**Status**: Submitted
**Primary Scope**: System theory / charter semantics / edge-case defense

---

## 1. Proposal Summary

当前系统的防御侧重点集中在事前认知与事后验收，**但在“执行中”（runtime）、“面临底层设施熔断（如限流断网）”以及“面对人类越权指令时”存在物理定义的真空**。
如果不修改，极易发生“执行态幻觉绕过真相源”、“底层限流导致全盘瘫痪”以及“人类责任转移导致系统背锅”的系统级雪崩。

---

## 2. Theory Change Items

| Proposal ID | Title | Current Problem | Proposed Change | Target Docs | Expected Effect | Risk |
|---|---|---|---|---|---|---|
| TC-ANTI-01 | 增加流程免审与快速通道 | "天条七"与三司会审过重冲突 | 补充《免审清单》机制，允许日常简单维护绕过重审计 | 00_Brain_Trust_Charter.md | 减少算力浪费 | 可能放过小错误 |
| TC-ANTI-02 | 引入执行期探针 (Runtime Watchdog) | 执行态(如脚本跑长循环)失控无事中拦截 | 在 `pangu` 等执行位或 `tester` 位引入事中斩杀机制 | 00_Brain_Trust_Charter.md | 防止长时间死锁或越界行为 | 探针过于敏感导致误杀 |
| TC-ANTI-03 | 增加越权免责留痕簿规则 | 面对人类强行覆盖规则时只能生硬抵触或默默背锅 | 天条一补充：人类动用终极拍板权强行绕过时，必须生成 `liability_shift_record.json` | 00_Brain_Trust_Charter.md | 物理断绝系统的责任风险 | 人类觉得繁琐 |
| TC-ANTI-04 | 学习闭环的“冷却区”隔离 | 罕见边界错误容易被固化为全局规则导致过拟合 | 引入错误复盘时的规则冷却期或特例区判定 | 00_Brain_Trust_Charter.md | 保证基础宪法不臃肿 | 偶尔同等错误会重新复现一次 |
| TC-ANTI-05 | 基础设施熔断与动态路由 | 物理层限流 (如 429 Rate Limit) 会导致上层网关死锁排队，Agent 兜底逻辑失效 | 规定系统必须外置或内置“环境探针”，当发现底层 API 被限流时，强制触发 Error Code 转换并启动备用模型 (Fallback) | 00_Brain_Trust_Charter.md | 防止物理断网导致系统假死，确保应急预案被正确激活 | 探针测活可能增加额外 API 请求成本 |

---

## 3. Detailed Rationale

### 3.1 Why This Is A Theory Change
这些不是修 Bug，而是关于系统怎么理解“执行授权”、“人类责任”与“学习边界”的根本认知。它决定了系统能不能在复杂的真实世界里不仅能抗压，还能聪明地保护自己。

### 3.2 Which Behaviors It Should Change
会让系统在面对极端施压时，有法理依据掏出免责声明，而不是陷入死锁；让系统在学习时有判断力，不把偶发错误当成必然真理。

### 3.3 Which Misreadings It Should Reduce
减少“所有改动都必须大兴土木评审”的教条主义；减少“人类说的都对所以我就得背锅”的认知混淆。

### 3.4 What Should Stay Unchanged
“天条四（不能绕过业务真相源）”和“天条五（技术不等于业务）”这种核心准绳绝对不能变。

---

## 4. Suggested Acceptance Rule

如果本理论修改被接受：
- 宪章第一部分应新增 `liability_shift_record.json` 的强制结构。
- 宪章第五部分（强制契约）应新增《免审清单》机制。
- 验收层面，应测试当长官强制下发违规命令时，系统是否输出了合规的免责声明再予放行。

---

## 5. Peer Review Ratings

> 写入前先读 [../../../00_REVIEW_START_HERE.md](../../../00_REVIEW_START_HERE.md) 和 [../review_status.yaml](../review_status.yaml)。  
> 每条评级都必须带证据锚点。

| Reviewer | Priority | Evidence Anchor | Reason |
|---|---|---|---|
| Codex |  |  |  |
| Kimi K2.5 |  |  |  |
| Qwen-3.5-Plus |  |  |  |
| Auto (Cursor) |  |  |  |
| MiniMax-M2.5 |  |  |  |
| Antigravity | self | self | self |

---

## 6. Rollup Hint

同步至 `docs/tests/theory_change_review_index.md`。
