return {
  "carlos-algms/agentic.nvim",
  opts = {
    provider = "codex-acp",
    acp_providers = {
      ["claude-acp"] = {
        command = "claude-code-acp",
      },
      ["codex-acp"] = {
        args = { "-c", 'approval_policy="untrusted"' },
      },
    },
  },
}
