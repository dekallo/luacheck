-- Generic validation script for testing the action's script execution.
-- Exits 0 if all checks pass.
local args = {...}
if #args > 0 and args[1] == "--fail" then
  io.stderr:write("Validation failed\n")
  os.exit(1)
end
print("Validation passed")
os.exit(0)
