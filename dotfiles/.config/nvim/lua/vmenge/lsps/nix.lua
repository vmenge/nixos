return {
    setup = function(opts)
        vim.lsp.enable("nil_ls")
        vim.lsp.config('nil_ls', {
            capabilities = opts.capabilities
        })
    end
}
