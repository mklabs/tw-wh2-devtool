
print("test required file");

local outputFunction, error = load("print('[test_ui] from loadingstring'); return 10;");
print("loadstring done");
if not outputFunction then
    print("Got an error: " .. error);
end

print("Calling outputFunction");

local ok, res = pcall(outputFunction);

if ok then
    print("res: " .. res);
else
    print("Got an output function error: " .. res);
end

print("end of loadstring magic");