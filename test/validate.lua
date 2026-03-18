-- Generic validation script for testing the action's custom_script execution.
-- Exits 0 if all checks pass.
--
-- Supported args:
--   --fail       Exit 1 (simulates script failure)
--   --echo a b c Print remaining args to stdout
local args = {...}
if #args > 0 and args[1] == "--fail" then
  io.stderr:write("Validation failed\n")
  os.exit(1)
end
if #args > 0 and args[1] == "--echo" then
  for i = 2, #args do
    print(args[i])
  end
  os.exit(0)
end
print("Validation passed")
os.exit(0)
