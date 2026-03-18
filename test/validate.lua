-- Generic validation script for testing the action's script execution.
-- Exits 0 if all checks pass.
-- Supports: --fail (exit 1), --echo a b c (print received args)
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
