# Open Source Release Checklist

这个清单面向 Claude Glance 首次或后续公开发布前的最终核对。

## 仓库边界

- [ ] 公开仓库根目录就是项目根目录
- [ ] 不把外层个人工作区文件一起公开
- [ ] 仓库名、应用名、README 标题保持一致

## 仓库卫生

- [ ] `git status --short` 中没有误提交的缓存、构建产物或个人文件
- [ ] `.derivedData/`、`.swift-module-cache/`、`dist/`、`default.profraw` 不在版本控制中
- [ ] 没有 `.DS_Store`、临时图片、测试残留文件
- [ ] Xcode 工程的 `project.pbxproj` 已纳入版本控制

## README 与文档

- [ ] README 顶部一句话讲清楚 Claude Glance 是什么
- [ ] README 包含真实截图或 GIF
- [ ] README 说明目标用户和非目标用户
- [ ] README 明确当前安装限制：unsigned / not notarized / no auto-update
- [ ] README 明确隐私和本地数据访问范围
- [ ] README 链接到 `CONTRIBUTING.md`、`SECURITY.md`、`SUPPORT.md`

## 发布可信度

- [ ] `LICENSE` 存在且与你的开源意图一致
- [ ] `CHANGELOG.md` 已更新
- [ ] `CONTRIBUTING.md` 内容与当前实际流程一致
- [ ] `SECURITY.md` 和 `SUPPORT.md` 已补齐
- [ ] GitHub Issue / PR 模板可正常使用

## 工程验证

- [ ] 本机可以成功 build
- [ ] 本机可以成功 test
- [ ] 从全新路径 clone 后仍能构建
- [ ] 首次打开流程与 README 描述一致
- [ ] 没有依赖本机私有路径、私有证书或未说明的工具链

## 发布产物

- [ ] `scripts/build-release.sh` 能稳定产出 `dist/ClaudeGlance.zip`
- [ ] Release 产物能在另一台机器上解压
- [ ] SHA-256 已重新计算
- [ ] Release 文案包含当前版本亮点和已知限制

## GitHub 仓库信息

- [ ] 仓库 description 已填写
- [ ] topics 已填写
- [ ] social preview 图已上传
- [ ] 首个 Release 标题和说明已准备好

## 建议的首发最低标准

如果你想先尽快公开，建议至少满足这些再发：

- [ ] README 可读
- [ ] 有 3 张截图
- [ ] build / test 至少在你本机跑通一次
- [ ] 仓库里没有缓存和产物垃圾
- [ ] Release 页面写清楚 unsigned / not notarized
