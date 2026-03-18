-- Writes a marker file to cwd. Validates that scripts can modify repo files.
local f = io.open("test/.written-by-script", "w")
if f then
  f:write("ok\n")
  f:close()
  os.exit(0)
else
  io.stderr:write("Could not write test/.written-by-script\n")
  os.exit(1)
end
