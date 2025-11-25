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

local function enqueue_with_depth(depth, fn, extra)
    extra = extra or {}
    G.E_MANAGER:add_event(Event({
        func = function()
            if depth == 0 then
                fn()
            else
                enqueue_with_depth(depth - 1, fn)
            end
            return true
        end,
        no_delete = extra.no_delete
    }))
end

local function run_test(test, mod_context, test_context)
    print('running test ' .. tostring(test_context.test_number) .. ' from ' .. mod_context.mod)
    test.jokers = test.jokers or {}
    test.play = test.play or {'H_A'}
    test.hand = test.hand or {}

    -- local original_game_over_state = G.STATES.GAME_OVER
    -- G.STATES.GAME_OVER = G.STATES.SELECTING_HAND

    for k, v in pairs(G.jokers.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.hand.cards) do
        v:start_dissolve(nil)
    end
    for k, v in pairs(G.deck.cards) do
        v:start_dissolve(nil)
    end

    for i, joker_key in ipairs(test.jokers) do
        local card = create_card('Joker', G.jokers, nil, 0, true, nil, joker_key)
        card:add_to_deck()
        G.jokers:emplace(card)
    end
    for i, key in ipairs(test.play) do
        local card = create_playing_card({
            front = G.P_CARDS[key]
        }, G.hand)
        G.hand:add_to_highlighted(card)
    end
    for i, key in ipairs(test.hand) do
        local card = create_playing_card({
            front = G.P_CARDS[key]
        }, G.hand)
    end
    -- enqueue_with_depth(2, function ()
    --     G.STATES.GAME_OVER = original_game_over_state
    -- end)
    enqueue_with_depth(2, G.FUNCS.play_cards_from_highlighted)
    enqueue_with_depth(5, function()
        if (test.expect.score and G.GAME.chips ~= test.expect.score) then
            test_context.fail('chips of '..G.GAME.chips..' did not match expected '..test.expect.score)
        end
    end)
end

local function run_tests(tests, mod_context)
    local function queue_test(index)
        local test_context = {
            test_number = index,
            failed = false,
            failure_reason = nil,
            name = 'test ' .. tostring(index) .. ' from ' .. mod_context.mod,
        }
        test_context.fail = function(reason)
            reason = reason or ''
            test_context.failed = true
            test_context.failure_reason = test_context.failure_reason or reason
        end
        if G.STAGE == G.STAGES.MAIN_MENU then
            G.FUNCS.start_setup_run()
        else
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
        enqueue_with_depth(9, function()
            G.blind_select_opts.small:get_UIE_by_ID('select_blind_button'):click()
        end, {
            no_delete = true
        })
        enqueue_with_depth(10, function()
            run_test(tests[index], mod_context, test_context)
            enqueue_with_depth(10, function()
                if test_context.failed then
                    sendWarnMessage('Failed: '..test_context.name.. (test_context.failure_reason and ': ' or '') ..test_context.failure_reason)
                    -- enqueue_with_depth(0,
                    --     function ()
                            --card_eval_status_text({}, 'extra', 1, 1, nil, {message = 'Failed: '..test_context.name, colour = G.C.MULT, no_juice = true})
                    --     end,
                    --     {no_delete = true}
                  --   )
                else
                    sendInfoMessage('Pass: '..test_context.name)
                    -- enqueue_with_depth(0, 
                    --     function ()
                            --card_eval_status_text({}, 'extra', 1, 1, nil, {message = 'Pass: '..test_context.name, colour = G.C.CHANCE, no_juice = true})
                    --     end,
                    --     {no_delete = true}
                    -- )
                end

                if index < #tests then
                    queue_test(index + 1)
                end
            end)
            return true
        end, {
            no_delete = true
        })
    end
    queue_test(1)
end

local function run_all()
    for key, mod in pairs(SMODS.Mods) do
        if mod.regression_tests then
            run_tests(mod.regression_tests, {
                mod = key
            })
        end
    end
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
        jokers = {'j_joker'},
        play = {'H_T', 'H_T', 'H_T', 'H_T', 'H_T'},
        expect = {
            score = 4200
        }
    },
    [2] = {
        jokers = {'j_joker', 'j_greedy_joker'},
        play = {'D_T', 'D_T', 'S_T'},
        expect = {
            score = 780
        }
    },
    [3] = {
        jokers = {'j_joker', 'j_greedy_joker'},
        play = {'D_T', 'D_T', 'S_T'},
        expect = {
            score = 1280
        }
    }
}
