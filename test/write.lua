-- Writes test/.written-by-script to cwd. Used by script-writes-repo workflow job
-- to verify that custom scripts can modify repo files (e.g. code generation).
local f = io.open("test/.written-by-script", "w")
if f then
  f:write("ok\n")
  f:close()
  os.exit(0)
else
  io.stderr:write("Could not write test/.written-by-script\n")
  os.exit(1)
end
