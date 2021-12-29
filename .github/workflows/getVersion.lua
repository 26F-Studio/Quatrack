local arg=arg[1]
if arg=="-apkCode"then
    local str=require"version".apkCode
    print(str)
elseif arg=="-versionName"then
    local str=require"version".string
    print(str)
elseif arg=="-versionCode"then
    local str=require"version".string:gsub("V","",1)
    print(str)
--elseif arg=="-updateTitle"then
--    local note=require"parts.updateLog"
--    local p1=note:find("\n%d")+1
--    local p2=note:find("\n",p1)-1
--    note=note:sub(p1,p2)
--    print(note)
--elseif arg=="-updateNote"then
--    local note=require"parts.updateLog"
--    local p1=note:find("\n",note:find("\n%d")+1)+1
--    local p2=note:find("\n%d",p1+1)
--    note=note:sub(p1,p2-2)
--        :gsub("                ","- ")
--        :gsub("        ","# ")
--    print(note)
end
