
local RegressionTester = SMODS.Mods.RegressionTester
RegressionTester.Vanilla = {}
local Vanilla = RegressionTester.Vanilla
local constants = RegressionTester.constants

local function play_hand_with_jokers_test(test_name, create_jokers, create_selected, expected_score)
    return {
        name = test_name,
        actions = {
            { action = 'Select_Blind', args = 'small'},
            { action = 'Create_Cards', args = {
                jokers = create_jokers,
                selected = create_selected,
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = expected_score,
            }}
        }
    }
end

Vanilla.regression_tests = {
    play_hand_with_jokers_test(
        'Joker',
        {'j_joker'},
        {'S_4', 'H_4', 'C_4', 'D_4'},
        (constants.FOUR_OF_A_KIND_CHIPS + 4 * 4) * (constants.FOUR_OF_A_KIND_MULT + 4)
    ),
    play_hand_with_jokers_test(
        'Greedy Joker',
        {'j_greedy_joker'},
        {'D_4', 'D_4', 'D_4', 'S_4'},
        (constants.FOUR_OF_A_KIND_CHIPS + 4 * 4) * (constants.FOUR_OF_A_KIND_MULT + 3 * 3)
    ),
    play_hand_with_jokers_test(
        'Lusty Joker',
        {'j_lusty_joker'},
        {'H_4', 'H_4', 'H_4', 'C_4'},
        (constants.FOUR_OF_A_KIND_CHIPS + 4 * 4) * (constants.FOUR_OF_A_KIND_MULT + 3 * 3)
    ),
    play_hand_with_jokers_test(
        'Wrathful Joker',
        {'j_wrathful_joker'},
        {'S_4', 'S_4', 'S_4', 'H_4'},
        (constants.FOUR_OF_A_KIND_CHIPS + 4 * 4) * (constants.FOUR_OF_A_KIND_MULT + 3 * 3)
    ),
    play_hand_with_jokers_test(
        'Gluttonous Joker',
        {'j_gluttenous_joker'},
        {'C_4', 'C_4', 'C_4', 'D_4'},
        (constants.FOUR_OF_A_KIND_CHIPS + 4 * 4) * (constants.FOUR_OF_A_KIND_MULT + 3 * 3)
    ),
    play_hand_with_jokers_test(
        'Jolly Joker',
        {'j_jolly'},
        {'H_5', 'S_5'},
        (constants.PAIR_CHIPS + 5 * 2) * (constants.PAIR_MULT + 8)
    ),
    play_hand_with_jokers_test(
        'Zany Joker',
        {'j_zany'},
        {'H_5', 'S_5', 'D_5'},
        (constants.THREE_OF_A_KIND_CHIPS + 5 * 3) * (constants.THREE_OF_A_KIND_MULT + 12)
    ),
    play_hand_with_jokers_test(
        'Mad Joker',
        {'j_mad'},
        {'H_5', 'S_5', 'D_4', 'C_4'},
        (constants.TWO_PAIR_CHIPS + 5 * 2 + 4 * 2) * (constants.TWO_PAIR_MULT + 10)
    ),
    play_hand_with_jokers_test(
        'Crazy Joker',
        {'j_crazy'},
        {'H_3', 'S_4', 'D_5', 'C_6', 'H_7'},
        (constants.STRAIGHT_CHIPS + 3 + 4 + 5 + 6 + 7) * (constants.STRAIGHT_MULT + 12)
    ),
    play_hand_with_jokers_test(
        'Droll Joker',
        {'j_droll'},
        {'H_3', 'H_4', 'H_3', 'H_4', 'H_7'},
        (constants.FLUSH_CHIPS + 3 + 4 + 3 + 4 + 7) * (constants.FLUSH_MULT + 10)
    ),
    play_hand_with_jokers_test(
        'Sly Joker',
        {'j_sly'},
        {'H_5', 'S_5'},
        (constants.PAIR_CHIPS + 5 * 2 + 50) * (constants.PAIR_MULT)
    ),
    play_hand_with_jokers_test(
        'Wily Joker',
        {'j_wily'},
        {'H_5', 'S_5', 'D_5'},
        (constants.THREE_OF_A_KIND_CHIPS + 5 * 3 + 100) * (constants.THREE_OF_A_KIND_MULT)
    ),
    play_hand_with_jokers_test(
        'Clever Joker',
        {'j_clever'},
        {'H_5', 'S_5', 'D_4', 'C_4'},
        (constants.TWO_PAIR_CHIPS + 5 * 2 + 4 * 2 + 80) * (constants.TWO_PAIR_MULT)
    ),
    play_hand_with_jokers_test(
        'Devious Joker',
        {'j_devious'},
        {'H_3', 'S_4', 'D_5', 'C_6', 'H_7'},
        (constants.STRAIGHT_CHIPS + 3 + 4 + 5 + 6 + 7 + 100) * (constants.STRAIGHT_MULT)
    ),
    play_hand_with_jokers_test(
        'Crafty Joker',
        {'j_crafty'},
        {'H_3', 'H_4', 'H_3', 'H_4', 'H_7'},
        (constants.FLUSH_CHIPS + 3 + 4 + 3 + 4 + 7 + 80) * (constants.FLUSH_MULT)
    ),
    {
        name = 'Half Joker',
        actions = {
            { action = 'Select_Blind', args = 'small'},
            { action = 'Set_Blind_Chips', args = 4.2e42 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = { 'j_half' },
                selected = {'S_K', 'S_Q', 'S_J', 'S_5', 'H_5'},
                hand = {'C_5', 'D_5'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (constants.PAIR_CHIPS + 5 + 5) * (constants.PAIR_MULT),
            }},
            { action = 'Select_Cards_From_Hand', args = { 1, 2 }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (constants.PAIR_CHIPS + 5 + 5) * (constants.PAIR_MULT) + (constants.PAIR_CHIPS + 5 + 5) * (constants.PAIR_MULT + 20),
            }},
        }
    },
    {
        name = 'Stencil',
        actions = {
            { action = 'Select_Blind', args = 'small'},
            { action = 'Set_Blind_Chips', args = 4.2e42 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = {'j_joker', 'j_stencil', 'j_stencil'},
                selected = {'H_2'},
                hand = {'S_2', 'D_2'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT + 4) * 4 * 4,
            }},
            { action = 'Sell_Joker', args = { key = 'j_joker' }},
            { action = 'Select_Cards_From_Hand', args = { 1 }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT + 4) * 4 * 4 +
                    (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT) * 5 * 5
                ),
            }},
            { action = 'Create_Cards', args = { jokers = { 'j_joker', 'j_joker' } }},
            { action = 'Move_Joker_To_Left', args = { index = 3 }},
            { action = 'Move_Joker_To_Left', args = { index = 4 }},
            { action = 'Select_Cards_From_Hand', args = { 1 }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT + 4) * 4 * 4 +
                    (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT) * 5 * 5 +
                    (constants.HIGH_CARD_CHIPS + 2) * (constants.HIGH_CARD_MULT + 4 + 4) * 3 * 3
                ),
            }},
        }
    },
    {
        name = 'Four Fingers',
        actions = {
            { action = 'Select_Blind', args = 'small'},
            { action = 'Set_Blind_Chips', args = 4.2e42 },
            { action = 'Set_Hands', args = 4.2e42 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = { 'j_four_fingers' },
                selected = {'S_K', 'S_Q', 'S_J', 'S_5', 'H_5'},
                hand = {'D_2', 'D_2', 'D_2', 'D_2'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.FLUSH_CHIPS + 10 + 10 + 10 + 5) * (constants.FLUSH_MULT)
                ),
            }},
            { action = 'Create_Cards', args = {
                selected = {'C_A', 'D_2', 'D_3', 'C_4'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.FLUSH_CHIPS + 10 + 10 + 10 + 5) * (constants.FLUSH_MULT) +
                    (constants.STRAIGHT_CHIPS + 11 + 2 + 3 + 4) * (constants.STRAIGHT_MULT)
                ),
            }},
            { action = 'Create_Cards', args = {
                selected = {'H_9', 'H_7', 'H_8', 'D_T', 'H_2'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.FLUSH_CHIPS + 10 + 10 + 10 + 5) * (constants.FLUSH_MULT) +
                    (constants.STRAIGHT_CHIPS + 11 + 2 + 3 + 4) * (constants.STRAIGHT_MULT) +
                    (constants.STRAIGHT_FLUSH_CHIPS + 7 + 9 + 8  + 10 + 2) * (constants.STRAIGHT_FLUSH_MULT)
                ),
            }},
            { action = 'Create_Cards', args = {
                selected = {'S_7', 'C_7', 'S_7', 'S_T', 'S_T'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.FLUSH_CHIPS + 10 + 10 + 10 + 5) * (constants.FLUSH_MULT) +
                    (constants.STRAIGHT_CHIPS + 11 + 2 + 3 + 4) * (constants.STRAIGHT_MULT) +
                    (constants.STRAIGHT_FLUSH_CHIPS + 7 + 9 + 8  + 10 + 2) * (constants.STRAIGHT_FLUSH_MULT) +
                    (constants.FLUSH_HOUSE_CHIPS + 7 + 7 + 7 + 10 + 10) * (constants.FLUSH_HOUSE_MULT)
                ),
            }},
            { action = 'Create_Cards', args = {
                selected = {'D_A', 'D_A', 'S_A', 'D_A', 'D_A'},
            }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                score = (
                    (constants.FLUSH_CHIPS + 10 + 10 + 10 + 5) * (constants.FLUSH_MULT) +
                    (constants.STRAIGHT_CHIPS + 11 + 2 + 3 + 4) * (constants.STRAIGHT_MULT) +
                    (constants.STRAIGHT_FLUSH_CHIPS + 9 + 7 + 8 + 10 + 2) * (constants.STRAIGHT_FLUSH_MULT) +
                    (constants.FLUSH_HOUSE_CHIPS + 7 + 7 + 7 + 10 + 10) * (constants.FLUSH_HOUSE_MULT) +
                    (constants.FLUSH_FIVE_CHIPS + 11 + 11 + 11 + 11 + 11) * (constants.FLUSH_FIVE_MULT)
                ),
            }},
        }
    },
    {
        name = 'Mime',
        actions = {
            { action = 'Select_Blind', args = 'small' },
            { action = 'Set_Blind_Chips', args = 1 },
            { action = 'Set_Money', args = 0 },
            { action = 'Destroy_All_Cards' },
            { action = 'Create_Cards', args = {
                jokers = { 'j_mime', 'j_oops', 'j_reserved_parking', 'j_raised_fist', 'j_baron', 'j_shoot_the_moon' },
                consumeables = { 'c_chariot', 'c_devil', 'c_trance' },
                hand = {'D_A', 'D_K', 'D_Q', 'D_J', 'D_T', 'D_9', 'D_8', 'D_3', 'D_3'},
            }},
            { action = 'Select_Cards_From_Hand', args = { 5 }},
            { action = 'Use_Consumeable', args = { key = 'c_chariot' }},
            { action = 'Select_Cards_From_Hand', args = { 6 }},
            { action = 'Use_Consumeable', args = { key = 'c_devil' }},
            { action = 'Select_Cards_From_Hand', args = { 7 }},
            { action = 'Use_Consumeable', args = { key = 'c_trance' }},
            { action = 'Select_Cards_From_Hand', args = { 8, 9 }},
            { action = 'Play_Hand' },
            { action = 'Expect', args = {
                consumeables = { 'c_mercury', 'c_mercury' },
                score = (constants.PAIR_CHIPS + 3 + 3) * ((constants.PAIR_MULT * 1.5 * 1.5 + 13 + 13) * 1.5 * 1.5 + 16 + 16),
                dollars = 1 * 2 * 3 + 3 * 2,
            }},
        },
    },
    {
        name = 'Credit Card',
        actions = {
            { action = 'Select_Blind', args = 'small'} ,
            { action = 'Create_Cards', args = {
                jokers = { 'j_credit_card' },
            }},
            { action = 'Win_Blind' },
            { action = 'Cash_Out' },
            { action = 'Set_Money', args = 11 },
            { action = 'Create_Shop', args = {
                jokers = {'j_blueprint', 'j_brainstorm', 'j_perkeo'},
            }},
            { action = 'Buy_From_Shop', args = { key = 'j_blueprint' } },
            { action = 'Buy_From_Shop', args = { key = 'j_perkeo' } },
            { action = 'Buy_From_Shop', args = { key = 'j_brainstorm' } },
            { action = 'Expect', args = {
                jokers = { 'j_credit_card', 'j_blueprint', 'j_perkeo' },
                dollars = -19,
            }},
        }
    }
}


