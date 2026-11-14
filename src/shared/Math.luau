local Math = {}

function Math.clamp(num: number, min: number, max: number)
	if num < min then
		return min
	end
	if num > max then
		return max
	end

	return num
end

return Math
