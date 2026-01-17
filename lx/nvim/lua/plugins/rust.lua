return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false, -- Already lazy-loads on rust filetypes
    ft = { "rust" },
    config = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(_, bufnr)
            local opts = { buffer = bufnr }
            -- Hover actions
            vim.keymap.set("n", "<Leader>rh", function()
              vim.cmd.RustLsp({ "hover", "actions" })
            end, opts)
            -- Code action groups
            vim.keymap.set("n", "<Leader>ra", function()
              vim.cmd.RustLsp("codeAction")
            end, opts)
            -- Run
            vim.keymap.set("n", "<Leader>rr", function()
              vim.cmd.RustLsp("runnables")
            end, opts)
            -- Debug
            vim.keymap.set("n", "<Leader>rd", function()
              vim.cmd.RustLsp("debuggables")
            end, opts)
          end,
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
      }
    end,
  },
}
