return {
  "carlos-algms/agentic.nvim",
  opts = {
    provider = "codex-acp",
    acp_providers = {
      ["codex-acp"] = {
        args = { "-c", 'approval_policy="untrusted"' },
      },
    },
  },
}
