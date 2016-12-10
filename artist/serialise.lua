local luaKeywords = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
	["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
	["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
	["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
	["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true,
}

local function serialiseImpl(t, tracking, out)
	local ty = type(t)
	if ty == "table" then
		if tracking[t] ~= nil then
			error("Cannot serialize table with recursive entries")
		end
		tracking[t] = true

		out[#out + 1] = "{"

		local seen = {}
		for k,v in ipairs(t) do
			seen[k] = true
			serialiseImpl(v, tracking, out)
			out[#out + 1] = ","
		end
		for k,v in pairs(t) do
			if not seen[k] then
				local entry
				if type(k) == "string" and not luaKeywords[k] and string.match( k, "^[%a_][%a%d_]*$" ) then
					out[#out + 1] = k .. "="
					serialiseImpl(v, tracking, out)
				else
					out[#out + 1] = "["
					serialiseImpl(k, tracking, out)
					out[#out + 1] = "]="
					serialiseImpl(v, tracking, out)
				end
				out[#out + 1] = ","
			end
		end
		out[#out + 1] = "}"
	elseif ty == "string" then
		out[#out + 1] = string.format("%q", t)
	elseif ty == "number" or ty == "boolean" or ty == "nil" then
		out[#out + 1] = tostring(t)
	else
		error("Cannot serialize type " .. ty)
	end
end

local function serialise(t)
	local out = {}
	serialiseImpl( t, {}, out)
	return table.concat(out)
end

local function deserialise(s)
	local func = load("return " .. s, "unserialize", "t", {})
	if func then
		local ok, result = pcall(func)
		if ok then
			return result
		end
	end
	return nil
end

return {
	serialise   = serialise,
	deserialise = deserialise,
	unserialise = deserialise,
}
