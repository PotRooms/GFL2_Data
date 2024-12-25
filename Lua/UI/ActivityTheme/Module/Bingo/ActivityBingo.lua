local PosDefine = {
  [1] = "A",
  [2] = "B",
  [3] = "C",
  [4] = "D",
  [5] = "E",
  [6] = "F",
  [7] = "G",
  [8] = "H",
  [9] = "I"
}
ActivityBingo = {}

function ActivityBingo.XY2Key(x, y)
  return PosDefine[x] .. y
end

function ActivityBingo.XY2Index(x, y, xMax)
  return (x - 1) * xMax + (y - 1)
end
