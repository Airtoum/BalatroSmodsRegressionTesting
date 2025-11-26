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
local LOGGER_NAME = 'RegressionTester'
RegressionTester.DEFAULT_REGRESSION_TEST_SEED = 'RegressionTests'

RegressionTester.actions = {}

local function string_join(t, delimiter)
    local string_acc = ''
    for i, v in ipairs(t) do
        string_acc = string_acc .. tostring(v)
        if i > 1 then
            string_acc = delimiter .. string_acc
        end
    end
    return string_acc
end

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
            with_patience(patience - 1, ready_fn, fn, out_of_patience_fn)
        else
            fn()
        end
    end)
end

function RegressionTester.actions.Noop(test_context, args)
    return { loops = 0 }
end

function RegressionTester.actions.Missing_Action(test_context, args)
    test_context.fail_and_stop('Test runner does not have an action named "'.. tostring(args)..'"')
    return { loops = 0 }
end

function RegressionTester.actions.Loop(test_context, args)
    return { loops = args.loops }
end

function RegressionTester.actions.Select_Blind(test_context, args)
    local blind = args or 'small'
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

function RegressionTester.actions.Destroy_Jokers(test_context, args)
    for k, v in pairs(G.jokers.cards) do
        v:start_dissolve(nil)
    end
end

function RegressionTester.actions.Destroy_Consumeables(test_context, args)
    for k, v in pairs(G.consumeables.cards) do
        v:start_dissolve(nil)
    end
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
        sendWarnMessage('Test Runner is playing a hand with 0 cards selected (this may crash, unless a mod supports this)', LOGGER_NAME)
    end
    G.FUNCS.play_cards_from_highlighted()
    return { loops = 3 }
end

function RegressionTester.actions.Discard(test_context, args)
    if #G.hand.highlighted == 0 then
        sendWarnMessage('Test Runner is discarding with 0 cards selected', LOGGER_NAME)
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

function RegressionTester.expect_card_keys_in_cardarea(test_context, cardarea_name, cardarea, expected)
    local expected_multiset = {}
    local actual_multiset = {}
    local actual_keys = {}
    for j, expected_key in ipairs(expected) do
        expected_multiset[expected_key] = (expected_multiset[expected_key] or 0) + 1
    end
    for i, card in ipairs(cardarea.cards) do
        actual_multiset[card.config.center.key] = (actual_multiset[card.config.center.key] or 0) + 1
        table.insert(actual_keys, card.config.center.key)
    end
    -- missing, wrong amount
    for expected_key, expected_count in pairs(expected_multiset) do
        local actual_count = (actual_multiset[expected_key] or 0)
        if actual_count ~= expected_count then
            test_context.fail('Expected '..cardarea_name..' to have '.. tostring(expected_count) .. ' of ' .. expected_key .. ' but there is '.. tostring(actual_count))
        end
    end
    -- extra when not specified
    for actual_key, actual_count in pairs(actual_multiset) do
        local expected_count = (expected_multiset[actual_key] or 0)
        if actual_count ~= expected_count then
            test_context.fail('Expected '..cardarea_name..' to have '.. tostring(expected_count) .. ' of ' .. actual_key .. ' but there is '.. tostring(actual_count))
        end
    end
    -- out of order
    for j, expected_key in ipairs(expected) do
        local card = cardarea.cards[j]
        if card and card.config and card.config.center and card.config.center.key ~= expected_key then
            test_context.fail('Expected '..cardarea_name..' to be ordered like {'..string_join(expected, ', ')..'} but they are instead ordered like {'..string_join(actual_keys, ', ')..'}')
            break
        end
    end
end

function RegressionTester.actions.Expect(test_context, args)
    if (args.score) then
        RegressionTester.expect_equal(test_context, 'G.GAME.chips', G.GAME.chips, args.score)
    end
    if (args.dollars) then
        RegressionTester.expect_equal(test_context, 'G.GAME.dollars', G.GAME.dollars, args.dollars)
    end
    if (args.jokers) then
        RegressionTester.expect_card_keys_in_cardarea(test_context, 'Jokers', G.jokers, args.jokers)
    end
    if (args.consumeables) then
        RegressionTester.expect_card_keys_in_cardarea(test_context, 'Consumeables', G.consumeables, args.consumeables)
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

-- implementation was stolen from DebugPlus
function RegressionTester.actions.Win_Blind(test_context, args)
    if G.STATE ~= G.STATES.SELECTING_HAND then
            return
    end
    G.GAME.chips = G.GAME.blind.chips
    G.STATE = G.STATES.HAND_PLAYED
    G.STATE_COMPLETE = true
    end_round()
    return { loops = 3 }
end

function RegressionTester.actions.Cash_Out(test_context, args)
    enqueue_with_depth(4, function ()
        G.FUNCS.cash_out({config = {}})
    end)
    return { loops = 4 + 6 }
end

function RegressionTester.actions.Destroy_Shop(test_context, args)
    for k, v in pairs(G.shop_jokers.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.shop_booster.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.shop_vouchers.cards) do
        v:start_dissolve(nil)
    end
    return { loops = 0 }
end

function RegressionTester.actions.Create_Shop(test_context, args)
    args = args or {}
    args.jokers = args.jokers or {}
    args.boosters = args.boosters or {}
    args.vouchers = args.vouchers or {}
    for i, key in ipairs(args.jokers) do
        local card = create_card('Joker', G.shop_jokers, nil, 0, true, nil, key)
        G.shop_jokers:emplace(card)
        create_shop_card_ui(card, 'Joker', G.shop_jokers)
    end
    for i, key in ipairs(args.boosters) do
        local card = create_card('Joker', G.shop_booster, nil, 0, true, nil, key)
        G.shop_booster:emplace(card)
        create_shop_card_ui(card, 'Joker', G.shop_booster)
    end
    for i, key in ipairs(args.vouchers) do
        local card = create_card('Joker', G.shop_vouchers, nil, 0, true, nil, key)
        G.shop_vouchers:emplace(card)
        create_shop_card_ui(card, 'Joker', G.shop_vouchers)
    end
    return { loops = 3 }
end

-- todo: G.pack_cards
function RegressionTester.actions.Buy_From_Shop(test_context, args)
    args = args or {}
    local button_key = args.buy_and_use and 'buy_and_use_button' or 'buy_button'
    local index = args.index
    if not index and args.key then
        for i, card in ipairs(G.shop_jokers.cards) do
            if card and card.config and card.config.center and card.config.center.key == args.key then
                index = i
                break
            end
        end
    end
    index = index or 1
    if (
        not G or
        not G.shop_jokers or
        not G.shop_jokers.cards or
        not G.shop_jokers.cards[index] or
        not G.shop_jokers.cards[index].children or
        not G.shop_jokers.cards[index].children[button_key] or
        not G.shop_jokers.cards[index].children[button_key].UIRoot or
        not G.shop_jokers.cards[index].children[button_key].UIRoot.children or
        not G.shop_jokers.cards[index].children[button_key].UIRoot.children[1] or
        not G.shop_jokers.cards[index].children[button_key].UIRoot.children[1].click
    ) then
        test_context.fail_and_stop('Test runner could not find the "'..button_key..'" for shop joker '.. tostring(args.key or index))
    else
        G.shop_jokers.cards[index].children[button_key].UIRoot.children[1]:click()
    end
    return { loops = 4 }
end

function RegressionTester.actions.Buy_And_Use_From_Shop(test_context, args)
    args = args or {}
    args.buy_and_use = true
    return RegressionTester.actions.Buy_From_Shop(test_context, args)
end

function RegressionTester.actions.Exit_Shop(test_context, args)
    G.FUNCS.toggle_shop()
    return { loops = 4 }
end

local function run_test(test, mod_context, test_context)
    sendInfoMessage('Running test ' .. tostring(test_context.name), LOGGER_NAME)

    local instructions = test.actions
    instructions[0] = { action = 'Loop', args = { loops = 4 } }

    local instruction_number = 0
    local function queue_next_instruction()
        local instruction = instructions[instruction_number] 
        local missing_action = false
        local function set_missing_action() missing_action = true; return false end
        local action = (
            ((not instruction or not instruction.action) and 'Noop') or 
            (RegressionTester.actions[instruction.action] and instruction.action) or 
            (set_missing_action()) and 'Missing_Action'
        )
        -- sendInfoMessage(test_context.name..': '..((missing_action and instruction.action) or action), LOGGER_NAME)
        print(test_context.name..': '..((missing_action and instruction.action) or action))
        local action_function = RegressionTester.actions[action]
        local args = (missing_action and instruction.action) or (instruction and instruction.args)
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
            test.mod_test_group = mod_test_group
            test.mod_numbering = j
            table.insert(tests, test)
        end
    end
    local function queue_test(index)
        local test = tests[index]
        local test_name = (test.name and '['..tostring(test.mod_numbering)..': '..test.name..']') or '['..tostring(test.mod_numbering)..']'
        local test_context = {
            test_number = index,
            mod_numbering = test.mod_numbering,
            short_name = test_name,
            name = 'test ' .. test_name .. ' from ' .. test.mod_test_group.mod_key,
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
                    G.forced_seed = (test.seed or RegressionTester.DEFAULT_REGRESSION_TEST_SEED)
                    G.FUNCS.start_setup_run()
                else
                    if G.STATE == G.STATES.GAME_OVER then G.STATE = G.STATES.MENU end
                    G.SETTINGS.current_setup = 'New Run'
                    G.GAME.viewed_back = nil
                    G.run_setup_seed = G.GAME.seeded
                    G.challenge_tab = G.GAME and G.GAME.challenge and G.GAME.challenge_tab or nil
                    G.forced_seed, G.setup_seed = (test.seed or RegressionTester.DEFAULT_REGRESSION_TEST_SEED), nil
                    -- if G.GAME.seeded then G.forced_seed = G.GAME.pseudorandom.seed end
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
                run_test(test, test.mod_test_group, test_context)
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
                        sendWarnMessage('Failed: '..test_context.name.. (test_context.failure_reason and ': ' or '') ..test_context.failure_reason, LOGGER_NAME)
                    else
                        sendInfoMessage('Pass: '..test_context.name, LOGGER_NAME)
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
        name = 'Jimbo',
        seed = '12345',
        actions = {
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
        }
    },
    [2] = {
        name = 'Mult on play',
        actions = {
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
        }
    },
    [3] = {
        name = 'Test can fail',
        actions = {
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
        }
    },
    [4] = {
        name = 'Game Over',
        actions = {
            { action = 'Expect_Game_Over_By_End' },
            { action = 'Select_Blind', args = 'small' },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                selected = {'S_2'},
            }},
            { action = 'Play_Hand' },
            { action = 'Noop' }
        }
    },
    [5] = {
        name = 'Discard and Dollars',
        actions = {
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
    },
    [6] = {
        name = 'Seeded',
        seed = 'First Seed',
        actions = {
            { action = 'Select_Blind', args = 'small' },
            { action = 'Set_Money', args = 0 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = {'j_reserved_parking', 'j_bloodstone'},
                selected = {'H_T', 'H_T', 'H_T'},
                hand = {'H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = 270,
                dollars = 10,
            }},
        }
    },
    [7] = {
        name = 'Different Seed',
        seed = 'Second Seed',
        actions = {
            { action = 'Select_Blind', args = 'small' },
            { action = 'Set_Money', args = 0 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = {'j_reserved_parking', 'j_bloodstone'},
                selected = {'H_T', 'H_T', 'H_T'},
                hand = {'H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K','H_K'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = 180,
                dollars = 8,
            }},
        }
    },
    [8] = {
        name = 'Buy from Shop',
        actions = {
            { action = 'Select_Blind', args = 'small' },
            { action = 'Set_Money', args = 10 },
            { action = 'Win_Blind' },
            { action = 'Cash_Out' },
            { action = 'Destroy_Shop' },
            { action = 'Create_Shop', args = {
                jokers = {'j_mime', 'j_jolly', 'c_earth', 'c_fool'},
                boosters = {'p_buffoon_mega_1', 'p_arcana_mega_2'},
                vouchers = {'v_antimatter'},
            }},
            { action = 'Buy_And_Use_From_Shop', args = { index = 3 } },
            { action = 'Buy_From_Shop', args = { key = 'j_jolly' } },
            { action = 'Buy_From_Shop', args = { key = 'c_fool' } },
            { action = 'Buy_From_Shop', args = { key = 'j_mime' } },
            { action = 'Expect', args = {
                jokers = { 'j_jolly', 'j_mime' },
                consumeables = { 'c_fool' }
            }},
            { action = 'Exit_Shop' },
            { action = 'Select_Blind', args = 'big' },
        }
    }
}
