-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },
  opts = function(_, config)
    -- config variable is the default configuration table for the setup function call
    --

    local get_root = function()
      ---@type string|nil
      local root

      -- prefer getting from client
      local client = require("null-ls.client").get_client()
      if client then root = client.config.root_dir end

      -- if in named buffer, resolve directly from root_dir
      if not root then
        local fname = vim.api.nvim_buf_get_name(0)
        if fname ~= "" then root = require("null-ls.config").get().root_dir(fname) end
      end

      -- fall back to cwd
      local cwd, err_name, err_msg = vim.uv.cwd()
      assert(cwd, string.format("[Error %s]: %s", err_name, err_msg))

      return root or cwd
    end

    -- Function to check for ESLint config files
    local function has_eslint_config(params)
      -- Check for ESLint flat config files (new ESLint 9+ format)
      if
        params.root_has_file {
          "eslint.config.js",
          "eslint.config.mjs",
          "eslint.config.cjs",
          "eslint.config.mts",
          "eslint.config.cts",
        }
      then
        return true
      end

      -- Check for traditional ESLint config files
      if
        params.root_has_file {
          ".eslintrc",
          ".eslintrc.js",
          ".eslintrc.cjs",
          ".eslintrc.mjs",
          ".eslintrc.cts",
          ".eslintrc.mts",
          ".eslintrc.yaml",
          ".eslintrc.yml",
          ".eslintrc.json",
        }
      then
        return true
      end

      -- Check package.json for eslint config
      local has_package_json = params.root_has_file "package.json"
      if has_package_json then
        local package_json_path = get_root() .. "/package.json"
        local ok, lines = pcall(vim.fn.readfile, package_json_path)
        if ok and lines then
          local content_str = table.concat(lines, "\n") -- join lines into one string
          local ok2, package_json = pcall(vim.fn.json_decode, content_str)
          if ok2 and package_json then return package_json.eslintConfig ~= nil end
        end
      end

      return false
    end

    -- Check supported formatters and linters
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    config.sources = {
      -- Set a formatter
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
      require("none-ls.code_actions.eslint_d").with {
        condition = has_eslint_config,
      },
      require("none-ls.diagnostics.eslint_d").with {
        condition = has_eslint_config,
      },
      require("none-ls.formatting.eslint_d").with {
        condition = has_eslint_config,
      },
    }
    return config -- return final config table
  end,
}
