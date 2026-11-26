-- Number formatting for money, multipliers and stats.
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function withCommas(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

function Format.number(n)
	n = math.floor(n or 0)
	if math.abs(n) < 10000 then
		return withCommas(n)
	end
	local i, v = 1, n
	while math.abs(v) >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	local text = if math.abs(v) < 100 then (string.format("%.1f", v):gsub("%.0$", "")) else tostring(math.floor(v))
	return text .. SUFFIXES[i]
end

function Format.money(n)
	return "$" .. Format.number(n)
end

function Format.mult(m)
	return (string.format("%.2f", m):gsub("0$", ""):gsub("%.$", ""))
end

return Format
