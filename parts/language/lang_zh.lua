local C=COLOR
return{
    loadText={
        loadSFX="加载音效资源",
        loadVoice="加载语音资源",
        loadFont="缓存字体资源",
        loadModeIcon="加载模式图标",
        loadMode="加载模式",
        loadOther="加载杂项",
        finish="按任意键继续",
    },
    sureQuit="再按一次退出",
    sureReset="再按一次重置",
    newDay="新的一天,新的开始~",
    playedLong="已经玩很久了!注意休息!",
    playedTooMuch="今天玩太久啦!打块好玩但也要适可而止哦~",

    atkModeName={"随机","徽章","击杀","反击"},
    royale_remain="剩余 $1 名玩家",
    powerUp={[0]="000%UP","025%UP","050%UP","075%UP","100%UP"},
    cmb={nil,"1 Combo","2 Combo","3 Combo","4 Combo","5 Combo","6 Combo","7 Combo","8 Combo","9 Combo","10 Combo!","11 Combo!","12 Combo!","13 Combo!","14 Combo!","15 Combo!","16 Combo!","17 Combo!","18 Combo!","19 Combo!","MEGACMB"},
    spin="-spin",
    clear={"single","double","triple","Techrash","Pentacrash","Hexacrash"},
    mini="Mini",b2b="B2B ",b3b="B2B2B ",
    PC="Perfect Clear",HPC="Half Clear",
    replaying="[回放]",
    tasUsing="[TAS]",

    stage="关卡 $1 完成",
    great="Great!",
    awesome="Awesome.",
    almost="Almost!",
    continue="Continue.",
    maxspeed="最高速度",
    speedup="速度加快",
    missionFailed="非任务消除",

    speedLV="速度等级",
    piece="块数",line="行数",atk="攻击",eff="效率",
    rpm="RPM",tsd="T2",
    grade="段位",techrash="Techrash",
    wave="波数",nextWave="下一波",
    combo="Combo",maxcmb="Max Combo",
    pc="Perfect Clear",ko="KO",

    win="胜利",
    lose="失败",

    finish="完成",
    gamewin="胜利",
    gameover="游戏结束",

    pause="暂停",
    pauseCount="暂停统计",
    finesse_ap="All Perfect",
    finesse_fc="Full Combo",

    page="页面:",

    cc_fixed="不能同时开启CC和固定序列",
    cc_swap="不能同时开启CC和swap的暂存模式",
    ai_prebag="不能同时开启AI和含有非四连块的自定义序列",
    ai_mission="不能同时开启AI和自定义任务",
    switchSpawnSFX="请开启方块出生音效",
    needRestart="重新开始以生效",

    saveDone="保存成功!",
    saveError="保存失败:",
    saveError_duplicate="文件名重复",
    loadError="读取失败:",
    exportSuccess="导出成功",
    importSuccess="导入成功",
    dataCorrupted="数据损坏",
    pasteWrongPlace="提醒:可能粘贴错地方了",
    noFile="找不到文件",

    noScore="暂无成绩",
    modeLocked="暂未解锁",
    unlockHint="前一模式达到成绩B或以上即可解锁",
    highScore="最佳成绩",
    newRecord="打破纪录",

    replayBroken="无法加载该录像",

    getNoticeFail="拉取公告失败",
    oldVersion="最新版本$1可以下载了!",
    needUpdate="请更新游戏!",
    versionNotMatch="版本不一致!",
    notFinished="暂未完成,敬请期待!",

    jsonError="json错误",

    noUsername="请填写用户名",
    wrongEmail="邮箱格式错误",
    noPassword="请填写密码",
    diffPassword="两次密码不一致",
    registerRequestSent="注册请求已发送",
    registerSuccessed="注册成功!",
    loginSuccessed="登录成功",
    accessSuccessed="身份验证成功",

    wsConnecting="正在连接",
    wsFailed="连接失败",
    wsClose="连接被断开:",
    netTimeout="连接超时",

    onlinePlayerCount="在线人数",
    createRoomSuccessed="创建房间成功!",
    started="游戏中",
    joinRoom="进入房间",
    leaveRoom="离开房间",
    ready="各就各位!",
    connStream="正在连接",
    waitStream="等待其他人连接",
    spectating="观战中",
    chatRemain="人数:",
    chatStart="------消息的开头------",
    chatHistory="------以上是历史消息------",

    keySettingInstruction="点击添加键位绑定\nesc取消选中\n退格键清空选中",

    errorMsg="Techmino遭受了雷击,需要重新启动.\n我们已收集了一些错误信息,你可以向作者进行反馈.",

    staff={
        "作者:MrZ  邮箱:1046101471@qq.com",
        "使用LÖVE引擎",
        "",
        "程序: MrZ, Particle_G, [scdhh, FinnTenzor]",
        "美术: MrZ, Gnyar, C₂₉H₂₅N₃O₅, ScF, [旋律星萤, T0722]",
        "音乐: MrZ, 柒栎流星, ERM, Trebor, C₂₉H₂₅N₃O₅, [T0722, Aether]",
        "音效/语音: Miya, Xiaoya, Mono, MrZ, Trebor",
        "演出: 模电, HBM",
        "翻译: User670, MattMayuga, Mizu, Mr.Faq, ScF, C₂₉H₂₅N₃O₅",
        "",
        "特别感谢:",
        "Flyz, Big_True, NOT-A-ROBOT, 思竣, yuhao7370",
        "Farter, Teatube, 蕴空之灵, T9972, [All test staff]",
    },
    used=[[
    使用工具:
        Beepbox
        Goldwave
        GFIE
        FL Mobile
    使用库:
        Cold_Clear [MinusKelvin]
        json.lua [rxi]
        profile.lua [itraykov]
        simple-love-lights [dylhunn]
    ]],
    support="支持作者",
    group="官方QQ群:913154753",
    WidgetText={
        main={
            offline="单机游戏",
            qplay="快速开始",
            online="联网游戏",
            custom="自定义",
            setting="设置",
            stat="统计信息",
            dict="小Z词典",
            replays="录像回放",
        },
        pause={
            setting="设置(S)",
            replay="回放(P)",
            save="保存(O)",
            resume="继续(esc)",
            restart="重新开始(R)",
            quit="退出(Q)",
            tas="TAS (T)",
        },
        setting_game={
            title="游戏设置",
            graphic="←画面设置",
            sound="声音设置→",

            ctrl="控制设置",
            key="键位设置",
            touch="触屏设置",
            reTime="开局等待时间",
            RS="旋转系统",
            layout="外观",
            menuPos="菜单按钮位置",
            sysCursor="使用系统光标",
            autoPause="失去焦点自动暂停",
            swap="组合键切换攻击模式",
            autoSave="破纪录自动保存",
            simpMode="简洁模式",
        },
        setting_video={
            title="画面设置",
            sound="←声音设置",
            game="游戏设置→",

            block="方块可见",
            smooth="平滑下落",
            upEdge="3D方块",
            bagLine="包分界线",

            ghostType="阴影样式",
            ghost="阴影不透明度",
            center="旋转中心不透明度",
            grid="网格不透明度",
            lineNum="行号透明度",

            lockFX="锁定特效",
            dropFX="下落特效",
            moveFX="移动特效",
            clearFX="消除特效",
            splashFX="溅射特效",
            shakeFX="晃动特效",
            atkFX="攻击特效",

            frame="绘制帧率(%)",
            FTlock="逻辑追帧",

            text="消行文本",
            score="分数动画",
            bufferWarn="缓冲预警",
            showSpike="爆发累计",
            nextPos="生成预览",
            highCam="超屏视野",
            warn="死亡预警",

            clickFX="点按特效",
            power="电量显示",
            clean="绘制优化",
            fullscreen="全屏",
            bg="背景",

            blockSatur="方块饱和度",
            fieldSatur="场地饱和度",
        },
        setting_sound={
            title="声音设置",
            game="←游戏设置",
            graphic="画面设置→",

            mainVol="总音量",
            bgm="音乐",
            sfx="音效",
            stereo="立体声",
            spawn="方块生成",
            warn="危险警告",
            vib="振动",
            voc="语音",

            autoMute="失去焦点自动静音",
            fine="极简操作提示音",
            sfxPack="音效包",
            vocPack="语音包",
            apply="应用",
        },
    },
}
