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
p.api.register {
    name = "packageid",
    scope = "config",
    kind = "string"
}
p.api.register {
    name = "analyzer",
    scope = "config",
    kind = "list:string"
}
p.api.register {
    name = "copylib",
    scope = "config",
    kind = "list:string"
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
			p.w('<EmbeddedResource Include="' .. (cfg.resourcesdir) .. '\\**\\*" />')
		end
		if cfg.packageid then
			p.w('<PackageId>' .. (cfg.packageid) .. '</PackageId>')
			p.w('<RootNamespace>' .. (cfg.packageid) .. '</RootNamespace>')
		end
		if cfg.targetname then
			p.w('<AssemblyName>' .. (cfg.targetname) .. '</AssemblyName>')
		end
		-- Required to make premake parse the value ???
		if cfg.analyzer then
		end
		if cfg.copylib then
		end
    end)
    return calls
end)

-- Support for C# source analyzers/generators and lib copying
premake.override(premake.vstudio.dotnetbase, "projectReferences", function(base, prj) 
    base(prj)
	
	local cfg = p.project.getfirstconfig(prj)
	local analyzers = cfg.analyzer
	local copylib = cfg.copylib
	
	if #analyzers > 0 then
		p.w('<ItemGroup>')
		
		local vstudio = p.vstudio
		
		for _,analyzer in ipairs(analyzers) do
			local pr = p.workspace.findproject(cfg.workspace, analyzer)
			local relpath = vstudio.path(prj, vstudio.projectfile(pr))
			p.w('  <ProjectReference Include="' .. relpath .. '" ReferenceOutputAssembly="false" OutputItemType="Analyzer" />')
		end
		
		p.w('</ItemGroup>')
	end
	
	if #copylib > 0 then
		p.w('<ItemGroup>')
		
		for _,lib in ipairs(copylib) do
			local l = {}
			for s in lib:gmatch('([^:]+):?') do l[#l + 1] = s end
			p.w('  <ContentWithTargetPath Include="' .. l[1] .. '" TargetPath="' .. l[2] .. '" CopyToOutputDirectory="PreserveNewest" />')
		end
		
		p.w('</ItemGroup>')
	end
	
end)

return m
