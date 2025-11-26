--- STEAMODDED HEADER
--- MOD_NAME: Regression Tester
--- MOD_ID: RegressionTester
--- MOD_AUTHOR: [Airtoum]
--- MOD_DESCRIPTION: Automatically looks for and runs test suites from other mods
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]
--- BADGE_COLOR: 665A88
--- PREFIX: regressions
----------------------------------------------
------------MOD CODE -------------------------
local RegressionTester = SMODS.current_mod

local REGRESSION_TEST_QUEUE_NAME = 'regression_tests'

RegressionTester.actions = {}

local function enqueue_with_depth(depth, fn, extra, queue)
    extra = extra or {}
    queue = queue or nil
    if depth == 0 then
        fn()
        return
    end
    G.E_MANAGER:add_event(Event({
        func = function()
            enqueue_with_depth(depth - 1, fn)
            return true
        end,
        no_delete = extra.no_delete
    }), queue)
end

local function with_patience(patience, ready_fn, fn, out_of_patience_fn)
    if patience <= -1 then
        out_of_patience_fn()
        return
    end
    enqueue_with_depth(0, function ()
        if not ready_fn() then
            with_patience(patience - 1, ready_fn, fn)
        else
            fn()
        end
    end)
end

function RegressionTester.actions.Noop(test_context, args)
    return { loops = 0 }
end

function RegressionTester.actions.Missing_Action(test_context, args)
    test_context.fail_and_stop('Test runner does not have an action named "'.. args..'"')
    return { loops = 0 }
end

function RegressionTester.actions.Loop(test_context, args)
    return { loops = args.loops }
end

function RegressionTester.actions.Select_Blind(test_context, args)
    local blind = args.blind or 'small'
    with_patience(
        10,
        function ()
            return (
                G and
                G.blind_select_opts and
                G.blind_select_opts[blind] and
                G.blind_select_opts[blind]:get_UIE_by_ID('select_blind_button') and
                G.blind_select_opts[blind]:get_UIE_by_ID('select_blind_button').click
            )
        end,
        function ()
            G.blind_select_opts[blind]:get_UIE_by_ID('select_blind_button'):click()
        end,
        function () test_context.fail_and_stop('Test runner could not find "Select Blind button."') end
        )
    return { loops = 10 }
end

function RegressionTester.actions.Destroy_All_Cards(test_context, args)
    for k, v in pairs(G.jokers.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.hand.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.deck.cards) do
        v:start_dissolve(nil)
    end
    return { loops = 0 }
end

function RegressionTester.actions.Create_Cards(test_context, args)
    args = args or {}
    args.jokers = args.jokers or {}
    args.selected = args.selected or {}
    args.hand = args.hand or {}
    for i, joker_key in ipairs(args.jokers) do
        local card = create_card('Joker', G.jokers, nil, 0, true, nil, joker_key)
        card:add_to_deck()
        G.jokers:emplace(card)
    end
    for i, key in ipairs(args.selected) do
        local card = create_playing_card({
            front = G.P_CARDS[key]
        }, G.hand)
        G.hand:add_to_highlighted(card)
    end
    for i, key in ipairs(args.hand) do
        local card = create_playing_card({
            front = G.P_CARDS[key]
        }, G.hand)
    end
    return { loops = 3 }
end

function RegressionTester.actions.Play_Hand(test_context, args)
    if #G.hand.highlighted == 0 then
        sendWarnMessage('Test Runner is playing a hand with 0 cards selected (this may crash, unless a mod supports this)')
    end
    G.FUNCS.play_cards_from_highlighted()
    return { loops = 3 }
end

function RegressionTester.actions.Discard(test_context, args)
    if #G.hand.highlighted == 0 then
        sendWarnMessage('Test Runner is discarding with 0 cards selected')
    end
    G.FUNCS.discard_cards_from_highlighted()
    return { loops = 3 }
end

function RegressionTester.expect_equal(test_context, name, actual, expected)
    if actual ~= expected then
        local actual_repr = type(actual) == 'string' and ('"'..actual..'"') or tostring(actual)
        local expected_repr = type(expected) == 'string' and ('"'..expected..'"') or tostring(expected)
        test_context.fail(name..' of '..actual_repr..' did not match expected '..expected_repr)
    end
end

function RegressionTester.actions.Expect(test_context, args)
    if (args.score) then
        RegressionTester.expect_equal(test_context, 'G.GAME.chips', G.GAME.chips, args.score)
    end
    if (args.dollars) then
        RegressionTester.expect_equal(test_context, 'G.GAME.dollars', G.GAME.dollars, args.dollars)
    end
    return { loops = 0 }
end

function RegressionTester.actions.Expect_Game_Over_By_End(test_context, args)
    if args == nil then
        args = true
    end
    test_context.expect_game_over = args
    return { loops = 0 }
end

function RegressionTester.actions.Fail(test_context, args)
    args = args or 'A Fail instruction executed'
    test_context.fail(args)
    return { loops = 0 }
end

function RegressionTester.actions.Set_Money(test_context, args)
    ease_dollars(-G.GAME.dollars + args or 0, true)
    return { loops = 1 }
end

function RegressionTester.actions.Add_Money(test_context, args)
    ease_dollars(args or 0, true)
    return { loops = 1 }
end

function RegressionTester.actions.Set_Hand_Selection_Limit(test_context, args)
    G.hand.config.highlighted_limit = args or 0
    return { loops = 0 }
end

local function run_test(test, mod_context, test_context)
    print('running test ' .. tostring(test_context.test_number) .. ' from ' .. mod_context.mod_key)

    local instructions = test
    instructions[0] = { action = 'Loop', args = { loops = 4 } }

    local instruction_number = 0
    local function queue_next_instruction()
        local instruction = instructions[instruction_number] 
        local action = (
            ((not instruction or not instruction.action) and 'Noop') or 
            (RegressionTester.actions[instruction.action] and instruction.action) or 
            'Missing_Action'
        )
        print(action)
        local action_function = RegressionTester.actions[action]
        local args = instruction and instruction.args
        local action_result = action_function(test_context, args)
        local loops = (action_result and action_result.loops) or 0
        if not instructions[instruction_number + 1] then
            test_context.done()
        end
        if not test_context.finished then
            instruction_number = instruction_number + 1
            enqueue_with_depth(loops, queue_next_instruction)
        end
    end

    enqueue_with_depth(1, function ()
        queue_next_instruction()
    end, { no_delete = true })

end

local function run_tests(mod_test_groups)
    local tests = {}
    for i, mod_test_group in ipairs(mod_test_groups) do
        for j, test in ipairs(mod_test_group.tests) do
            table.insert(tests, { test = test, mod_test_group = mod_test_group })
        end
    end
    local function queue_test(index)
        local test_context = {
            test_number = index,
            name = 'test ' .. tostring(index) .. ' from ' .. tests[index].mod_test_group.mod_key,
            failed = false,
            failure_reason = nil,
            finished = false,
            expect_game_over = nil,
        }
        test_context.fail = function(reason)
            reason = reason or ''
            test_context.failed = true
            test_context.failure_reason = test_context.failure_reason or reason
        end
        function test_context.done()
            test_context.finished = true
        end
        function test_context.fail_and_stop(reason)
            test_context.fail(reason)
            test_context.done()
        end
        local original_g_funcs_hud_blind_debuff = G.FUNCS.HUD_blind_debuff
        G.E_MANAGER:add_event(Event({
            no_delete = true,
            pause_force = true,
            func = function()
                G.FUNCS.HUD_blind_debuff = function() end
                if G.STAGE == G.STAGES.MAIN_MENU then
                    G.FUNCS.start_setup_run()
                else
                    if G.STATE == G.STATES.GAME_OVER then G.STATE = G.STATES.MENU end
                    G.SETTINGS.current_setup = 'New Run'
                    G.GAME.viewed_back = nil
                    G.run_setup_seed = G.GAME.seeded
                    G.challenge_tab = G.GAME and G.GAME.challenge and G.GAME.challenge_tab or nil
                    G.forced_seed, G.setup_seed = nil, nil
                    if G.GAME.seeded then G.forced_seed = G.GAME.pseudorandom.seed end
                    G.forced_stake = G.GAME.stake
                    if G.STAGE == G.STAGES.RUN then G.FUNCS.start_setup_run() end
                    G.forced_stake = nil
                    G.challenge_tab = nil
                    G.forced_seed = nil
                end
                return true
            end,
        }), REGRESSION_TEST_QUEUE_NAME)
        
        G.E_MANAGER:add_event(Event({
            no_delete = true,
            pause_force = true,
            func = function()
                G.FUNCS.HUD_blind_debuff = original_g_funcs_hud_blind_debuff
                run_test(tests[index].test, tests[index].mod_test_group, test_context)
                return true
            end,
        }), REGRESSION_TEST_QUEUE_NAME)
        -- block regression test queue until finished
        G.E_MANAGER:add_event(Event({
            no_delete = true,
            pause_force = true,
            func = function()
                if G.STATE == G.STATES.GAME_OVER then
                    if (test_context.expect_game_over == false) then
                        test_context.fail('Test expected no game over to happen, but a game over happened')
                    end
                    test_context.done()
                end
                if test_context.finished then
                    if (test_context.expect_game_over == true and not G.STATE == G.STATES.GAME_OVER) then
                        test_context.fail('Test expected a game over to happen, but no game over happened')
                    end
                    if test_context.failed then
                        sendWarnMessage('Failed: '..test_context.name.. (test_context.failure_reason and ': ' or '') ..test_context.failure_reason)
                    else
                        sendInfoMessage('Pass: '..test_context.name)
                    end
                end
                return test_context.finished
            end,
        }), REGRESSION_TEST_QUEUE_NAME)
        delay(0.1, REGRESSION_TEST_QUEUE_NAME)
    end

    for i = 1, #tests do
        queue_test(i)
    end
end

local function run_all()
    G.E_MANAGER.queues[REGRESSION_TEST_QUEUE_NAME] = G.E_MANAGER.queues[REGRESSION_TEST_QUEUE_NAME] or {}
    local mod_test_groups = {}
    for key, mod in pairs(SMODS.Mods) do
        if mod.regression_tests then
            table.insert(mod_test_groups, { tests = mod.regression_tests, mod = mod, mod_key = key})
        end
    end
    run_tests(mod_test_groups)
end

SMODS.Keybind {
    key_pressed = 'f7',
    event = 'pressed',
    action = function(self)
        print('run tests')
        run_all()
    end
}

RegressionTester.regression_tests = {
    [1] = {
        { action = 'Select_Blind', args = 'small' },
        { action = 'Destroy_All_Cards' },
        { action = 'Create_Cards', args = {
            jokers = {'j_joker'},
            selected = {'H_T', 'H_T', 'H_T', 'H_T', 'H_T'}, 
        }},
        { action = 'Play_Hand' },
        { action = 'Expect', args = {
            score = 4200,
        }},
    },
    [2] = {
        { action = 'Select_Blind', args = 'small' },
        { action = 'Destroy_All_Cards' },
        { action = 'Create_Cards', args = {
            jokers = {'j_joker', 'j_greedy_joker'},
            selected = {'D_T', 'D_T', 'S_T'},
        }},
        { action = 'Play_Hand' },
        { action = 'Expect', args = {
            score = 780,
        }},
    },
    [3] = {
        { action = 'Select_Blind', args = 'small' },
        { action = 'Destroy_All_Cards' },
        { action = 'Create_Cards', args = {
            jokers = {'j_joker', 'j_greedy_joker'},
            selected = {'D_T', 'D_T', 'S_T'},
            hand = {'H_K','H_3','H_8','H_A','H_8'},
        }},
        { action = 'Play_Hand' },
        { action = 'Expect', args = {
            score = 'this test fails',
        }},
    },
    [4] = {
        { action = 'Expect_Game_Over_By_End' },
        { action = 'Select_Blind', args = 'small' },
        { action = 'Destroy_All_Cards' },
        { action = 'Create_Cards', args = {
            selected = {'S_2'},
        }},
        { action = 'Play_Hand' },
        { action = 'Noop' }
    },
    [5] = {
        { action = 'Select_Blind', args = 'small' },
        { action = 'Set_Money', args = 30 },
        { action = 'Set_Hand_Selection_Limit', args = 13 },
        { action = 'Destroy_All_Cards' },
        { action = 'Create_Cards', args = {
            jokers = {'j_castle', 'j_mail', 'j_burnt', 'j_hit_the_road'},
            selected = {'S_A', 'H_K', 'C_Q', 'D_J', 'S_T', 'S_9', 'S_8', 'S_7', 'S_6', 'S_5', 'S_4', 'S_3', 'S_2'},
        }},
        { action = 'Discard' },
        { action = 'Expect', args = {
            dollars = 35,
        }},
    }
}
