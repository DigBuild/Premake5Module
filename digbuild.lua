require('vstudio')

local p = premake
local m = {}

-- Make .NET 5 projects use the new project format
premake.override(premake.vstudio.dotnetbase, "isNewFormatProject", function(base, cfg)
    local framework = cfg.dotnetframework
    if framework and framework:find('^net5') ~= nil then
        return true
    end
    return base(cfg)
end)

-- Additional project options
p.api.register {
    name = "allownullable",
    scope = "config",
    kind = "boolean",
    default = false
}
p.api.register {
    name = "noframeworktag",
    scope = "config",
    kind = "boolean",
    default = false
}
p.api.register {
    name = "resourcesdir",
    scope = "config",
    kind = "string"
}
premake.override(premake.vstudio.cs2005.elements, "projectProperties", function(base, cfg) 
    local calls = base(cfg)
    table.insert(calls, function(cfg)
        if cfg.allownullable then
            p.w('<Nullable>enable</Nullable>')
        end
        if cfg.noframeworktag then
            p.w('<AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>')
        end
		if cfg.resourcesdir then
			p.w('<EmbeddedResource Include="' .. (cfg.resourcesdir) .. '\**\*" />')
		end
    end)
    return calls
end)

return m
