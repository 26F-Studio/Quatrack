local C=COLOR
return{
    loadText={
        loadSFX="Loading sound effects",
        loadVoice="Loading voice packs",
        loadFont="Loading fonts",
        loadModeIcon="Loading mode icons",
        loadMode="Loading modes",
        loadOther="Loading other assets",
        finish="Press any key to start!",
    },
    sureQuit="Press again to quit",
    sureReset="Press again to reset",
    newDay="A new day, a new beginning!",
    playedLong="You have been playing for a long time. Time to a break!",
    playedTooMuch="You have been playing for far too long! Techmino is fun, but remember to have some rests!",

    atkModeName={"Random","Badges","K.O.s","Attackers"},
    royale_remain="$1 Players Remains",
    powerUp={[0]="+000%","+025%","+050%","+075%","+100%"},
    cmb={nil,"1 Combo","2 Combo","3 Combo","4 Combo","5 Combo","6 Combo","7 Combo","8 Combo","9 Combo","10 Combo!","11 Combo!","12 Combo!","13 Combo!","14 Combo!!","15 Combo!!","16 Combo!!","17 Combo!!!","18 Combo!!!","19 Combo!!!","MEGACMB"},
    spin="-spin",
    clear={"Single","Double","Triple","Techrash","Pentacrash","Hexacrash"},
    mini="Mini",b2b="B2B ",b3b="B2B2B ",
    PC="Perfect Clear",HPC="Hemi-Perfect Clear",
    replaying="[Replay]",
    tasUsing="[TAS]",

    stage="Stage $1 completed",
    great="Great!",
    awesome="Awesome!",
    almost="Almost There!",
    continue="Keep Going!",
    maxspeed="MAX SPEED!",
    speedup="Speed Up!",
    missionFailed="Wrong Clear",

    speedLV="Speed Level",
    piece="Piece",line="Lines",atk="Attack",eff="Efficiency",
    rpm="RPM",tsd="TSD",
    grade="Grade",techrash="Techrash",
    wave="Wave",nextWave="Next",
    combo="Combo",maxcmb="Max Combo",
    pc="Perfect Clear",ko="KOs",

    win="Win",
    lose="Lose",

    finish="Finished",
    gamewin="You Win",
    gameover="Game Over",

    pause="Pause",
    pauseCount="Pauses",
    finesse_ap="All Perfect",
    finesse_fc="Full Combo",

    page="Page:",

    cc_fixed="CC is incompatible with fixed sequences",
    cc_swap="CC is incompatible with swap holdmode",
    ai_prebag="AI is incompatible with custom sequences which have non-tetromino",
    ai_mission="AI is incompatible with custom missions",
    switchSpawnSFX="Please turn on the block spawn SFX!",
    needRestart="Restart to apply all changes",

    saveDone="Data saved",
    saveError="Failed to save:",
    saveError_duplicate="Duplicated filename",
    loadError="Failed to load:",
    exportSuccess="Exported successfully",
    importSuccess="Imported successfully",
    dataCorrupted="Data corrupted",
    pasteWrongPlace="Paste at the wrong place?",
    noFile="File missing",

    noScore="No scores",
    modeLocked="Locked",
    unlockHint="Achieve Rank B or above in the preceding modes to unlock",
    highScore="High Scores",
    newRecord="New Record!",

    replayBroken="Cannot load replay",

    getNoticeFail="Failed to fetch announcements",
    oldVersion="Version $1 is now available",
    needUpdate="Newer version required!",
    versionNotMatch="Versions do not match!",
    notFinished="Coming soon!",

    jsonError="JSON error",

    noUsername="Please enter your username",
    wrongEmail="Invalid email address",
    noPassword="Please enter your password",
    diffPassword="Passwords don't match",
    registerRequestSent="Sign-up request sent",
    registerSuccessed="Sign-up succeeded",
    loginSuccessed="You are now logged in!",
    accessSuccessed="Access granted",

    wsConnecting="Websocket connecting…",
    wsFailed="WebSocket connection failed",
    wsClose="WebSocket closed:",
    netTimeout="Connection timed out",

    onlinePlayerCount="Online",
    createRoomSuccessed="Room created",
    started="Playing",
    joinRoom="has entered the room.",
    leaveRoom="has left the room.",
    ready="Ready",
    connStream="Connecting",
    waitStream="Waiting",
    spectating="Spectating",
    chatRemain="Online",
    chatStart="------Beginning of log------",
    chatHistory="------New messages below------",

    keySettingInstruction="Press to bind key\nescape: cancel\nbackspace: delete",

    errorMsg="Techmino ran into a problem and needs to restart.\nYou can send the error log to the developers.",

    staff={
        "Author: MrZ  Email: 1046101471@qq.com",
        "Powered by LÖVE",
        "",
        "Program: MrZ, Particle_G, [scdhh, FinnTenzor]",
        "Art: MrZ, Gnyar, C₂₉H₂₅N₃O₅, ScF, [旋律星萤, T0722]",
        "Music: MrZ, 柒栎流星, ERM, Trebor, C₂₉H₂₅N₃O₅, [T0722, Aether]",
        "Voice & Sound: Miya, Xiaoya, Mono, MrZ, Trebor",
        "Performance: 模电, HBM",
        "Translations: User670, MattMayuga, Mizu, Mr.Faq, ScF, C₂₉H₂₅N₃O₅",
        "",
        "Special Thanks:",
        "Flyz, Big_True, NOT-A-ROBOT, 思竣, yuhao7370",
        "Farter, Teatube, 蕴空之灵, T9972, [All test staff]",
    },
    used=[[
    Tools used:
        BeepBox
        GoldWave
        GFIE
        FL Mobile
    Libs used:
        Cold_Clear [MinusKelvin]
        json.lua [rxi]
        profile.lua [itraykov]
        simple-love-lights [dylhunn]
    ]],
    support="Support the author",
    group="Join our Discord: discord.gg/f9pUvkh",
    WidgetText={
        main={
            offline="Single Player",
            qplay="Last Played",
            online="Multiplayer",
            custom="Custom Game",
            setting="Settings",
            stat="Statistics",
            dict="Zictionary",
            replays="Replays",
        },
        pause={
            setting="Settings (S)",
            replay="Replay (P)",
            save="Save (O)",
            resume="Resume (esc)",
            restart="Retry (R)",
            quit="Quit (Q)",
            tas="TAS (T)",
        },
        setting_game={
            title="Game Settings",
            graphic="←Video",
            sound="Audio→",

            ctrl="Control Settings",
            key="Key Mappings",
            touch="Touch Settings",
            reTime="Start Delay",
            RS="Rotation System",
            layout="Layout",
            menuPos="Menu Button Pos.",
            sysCursor="Use System Cursor",
            autoPause="Pause When Unfocused",
            swap="Key Combination (Change Atk Mode)",
            autoSave="Auto Save New Records",
            simpMode="Simplistic Mode",
        },
        setting_video={
            title="Video Settings",
            sound="←Audio",
            game="Game→",

            block="Draw Blocks",
            smooth="Smooth Falling",
            upEdge="3D Block",
            bagLine="Bag Separators",

            ghostType="Ghost Type",
            ghost="Ghosts",
            center="Rotation Centers",
            grid="Grid",
            lineNum="line No.",

            lockFX="Lock FX",
            dropFX="Drop FX",
            moveFX="Move FX",
            clearFX="Clear FX",
            splashFX="Splash FX",
            shakeFX="Field Sway",
            atkFX="Atk FX",

            frame="Render Frame Rate (%)",
            FTlock="Frame skip",

            text="Line Clear Pop-Ups",
            score="Score Pop-Ups",
            bufferWarn="Buffer Alerts",
            showSpike="Spike Counter",
            nextPos="Next Preview",
            highCam="Screen Scrolling",
            warn="Danger Alerts",

            clickFX="Click FX",
            power="Battery Info",
            clean="Quick Draw",
            fullscreen="Fullscreen",
            bg="Background",

            blockSatur="Block Saturation",
            fieldSatur="Field Saturation",
        },
        setting_sound={
            title="Audio Settings",

            game="←Game",
            graphic="Video→",

            mainVol="Main Volume",
            bgm="BGM",
            sfx="SFX",
            stereo="Stereo",
            spawn="Spawn SFX",
            warn="Warning SFX",
            vib="Vibrations",
            voc="Voices",

            autoMute="Mute When Unfocused",
            fine="Finesse Error SFX",
            sfxPack="SFX Pack",
            vocPack="Voice Pack",
            apply="Apply",
        },
    },
}
