-- new-file skeletons for rails apps, through projectionist. global, so nothing
-- gets added to a repo's tracked files. vim-rails' own defaults don't fire here.

local function camelize(s)
	return (s:gsub("^%l", string.upper):gsub("_(%w)", string.upper))
end

-- nested modules, not Admin::Foo: that's what every smarttrackers app does.
-- input is the path under the projection's dir, e.g. "admin/user"
local function nested(input, suffix, parent, mod, body)
	local parts = vim.tbl_map(camelize, vim.split(input, "/", { plain = true }))
	parts[#parts] = parts[#parts] .. suffix
	local last = #parts
	local lines = {}
	local function add(depth, text)
		lines[#lines + 1] = string.rep("  ", depth) .. text
	end
	for i, p in ipairs(parts) do
		if i < last then
			add(i - 1, "module " .. p)
		elseif mod then
			add(i - 1, "module " .. p)
			if mod == "concern" then
				add(i, "extend ActiveSupport::Concern")
				lines[#lines + 1] = ""
			end
		else
			add(i - 1, "class " .. p .. (parent and (" < " .. parent) or ""))
		end
	end
	for _, l in ipairs(body or {}) do
		add(last, l)
	end
	for i = last, 1, -1 do
		add(i - 1, "end")
	end
	return "# frozen_string_literal: true\n\n" .. table.concat(lines, "\n")
end

local function kind(suffix, parent, body)
	return function(input)
		return nested(input, suffix, parent, nil, body)
	end
end

vim.g.projectionist_transformations = {
	rb_model = kind("", "ApplicationRecord"),
	rb_controller = kind("Controller", "ApplicationController"),
	rb_job = kind("Job", "ApplicationJob"),
	rb_mailer = kind("Mailer", "ApplicationMailer"),
	rb_policy = kind("Policy", "ApplicationPolicy"),
	rb_cell = kind("Cell", "ApplicationCell"),
	rb_resource = kind("Resource", "ApplicationResource"),
	rb_validator = kind("Validator", "ActiveModel::EachValidator", { "def validate_each(record, attribute, value)", "end" }),
	rb_serializer = kind("Serializer", nil, { "include PrivateApi::Serializer" }),
	rb_concern = function(input)
		return nested(input, "", nil, "concern")
	end,
	rb_helper = function(input)
		return nested(input, "Helper", nil, "plain")
	end,
	-- users/row_thing -> users--row-thing, stimulus' nested identifier
	stimulus = function(input)
		return (input:gsub("/", "--"):gsub("_", "-"))
	end,
}

local stimulus = {
	'import {open} Controller {close} from "@hotwired/stimulus";',
	"",
	'// Connects to data-controller="{stimulus}"',
	"export default class extends Controller {open}",
	"  connect() {open}",
	"  {close}",
	"{close}",
}

-- `type` is what gives each dir its :E/:S/:V/:T<type> commands
local function rb(name, type, spec)
	return {
		template = { "{" .. name .. "}" },
		type = type,
		alternate = spec and ("spec/" .. spec .. "_spec.rb"),
	}
end

vim.g.projectionist_heuristics = {
	["config/application.rb"] = {
		["app/models/*.rb"] = rb("rb_model"),
		["app/controllers/*_controller.rb"] = rb("rb_controller"),
		["app/models/concerns/*.rb"] = rb("rb_concern", "concern"),
		["app/controllers/concerns/*.rb"] = rb("rb_concern", "concern"),
		["app/jobs/*_job.rb"] = rb("rb_job"),
		["app/mailers/*_mailer.rb"] = rb("rb_mailer"),
		["app/helpers/*_helper.rb"] = rb("rb_helper"),
		["app/policies/*_policy.rb"] = rb("rb_policy", "policy", "policies/{}_policy"),
		["app/cells/*_cell.rb"] = rb("rb_cell", "cell", "cells/{}_cell"),
		["app/resources/*_resource.rb"] = rb("rb_resource", "resource", "resources/{}_resource"),
		["app/validators/*_validator.rb"] = rb("rb_validator", "validator", "validators/{}_validator"),
		["app/serializers/*_serializer.rb"] = rb("rb_serializer", "serializer", "serializers/{}_serializer"),
		["app/javascript/controllers/*_controller.js"] = { template = stimulus, type = "stimulus" },
	},
}

-- oil creates the file on disk before opening it, so BufNewFile never fires
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("RailsTemplatesEmpty", {}),
	pattern = { "*.rb", "*.js" },
	callback = function(ev)
		local blank = vim.api.nvim_buf_line_count(ev.buf) == 1 and vim.fn.getline(1) == ""
		if blank and vim.fn.getfsize(ev.file) == 0 and vim.b[ev.buf].projectionist then
			vim.fn["projectionist#apply_template"]()
		end
	end,
})
