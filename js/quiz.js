//
// mapping javascript client behavior to clojure server responses:
//
// js fn                        action:url                          clojure
// =================================================================================
//
// addguess()                   none                                none
// submit_user_response()       post:/quiz/evaluate                 (quiz/evaluate)
// get_next_question()          get: /quiz/question/                (quiz/question)
//                              get: /quiz/fillqueue/               (quiz/fillqueue)
// show_quiz_preferences()      get: /quiz/filter/                  ??
// show_question_types()        get: /quiz/filter/?format=titlebar  ??
// submit_quiz_filters()        post:/quiz/filter/                  ??
//

function addguess(english,italian) {
    $("#guess-table").prepend("<tr style='display:none' id='guess_row_" + guessNumber + "'><th>" + guessNumber + "</th><th>" + english + "</th><td>" + italian + "</td></tr>");
    $("#guess_row_"+guessNumber).fadeIn("slow");
    guessNumber++;
}

function fade_in(row_id) {
    $("#tr_"+row_id).fadeIn("fast");
}

function submit_user_response(form_input_id) {
    var guess = $("#"+form_input_id).val();

    // 1. apply user's guess to guess evaluation.
    $.ajax({
        dataType: "html",
        data: {guess: guess, qid: $("#question_id").val()},
        type: "POST",
        contentType: "application/x-www-form-urlencoded;charset=utf-8",
        url: "/quiz/evaluate/",
        success: function (content) {
            $("#quiz_table").prepend(content);
        }
    });
    // 2. generate a new question and present it to the user.
    get_next_question();
}

function get_next_question() {
    // first checks the Open Queue of questions for this user - if the
    // queue is not empty, take the first from there. Otherwise, generates
    // a new question.
    var hint = "";
    // TODO: a better user spinner than this..
    // (or even better, make finding a sentence so fast we don't need it).
    $("#ajax_question").html("Thinking of a good question for you..");

    $.ajax({
        dataType: "html",
        url: "/quiz/question/",
        success: function (content) {
            $("#ajax_question").html(content);
	    hint = content; // TODO: hintize.
	    // 3. initialize user's input so that user is ready to answer next question.
            set_guess_input('');
        }
    });

    // while user thinks about current question (filled in above), fill queue in the background so that user doesn't need to wait very long for the next question.
    $.ajax({
        dataType: "html",
        url: "/quiz/fillqueue/",
        success: function (content) {
            $("#queue_size").remove();
            $("#qa").append("<div id='queue_size'>xx</div>");
            $("#queue_size").html(content);
        }
    });

}

function set_guess_input(text) {
    $("#guess_input").val(text);
    $("#guess_input").focus();
    $("#guess_input").autoGrowInput({
	comfortZone: 70,
	minWidth: 410,
	maxWidth: 2000
    });
}

function remove_pluses(string) {
    var re = /\+/g;
    var newstr = string.replace(re, " ");
    return newstr;
}

function ajax_quiz(hint) {
    set_guess_input(hint);
}

function show_quiz_preferences() {
    $.ajax({
        dataType: "html",
        url: "/quiz/filter/",
        success: function (content) {
            $("#controls_container").html(content);
        }
    });
}

function show_question_types() {
    $.ajax({
        dataType: "html",
        type: "GET",
        url: "/quiz/filter/?format=titlebar",
        success: function (content) {
            $("#quizbanner").html(content);
        }
    });
}

function submit_quiz_filters(container, form) {
    $.ajax({
        dataType: "html",
        data: $(form).serialize(),
        type: "POST",
        contentType: "application/x-www-form-urlencoded;charset=utf-8",
        url: "/quiz/filter/",
        success: function (content) {
            $(container).html(content);

            // this should happen only in 'success' of POST to avoid
            // a race condition: don't query db for user's question types
            // until user's updated preferences have made it into the database.
            show_question_types();
        }
    });

}

function table_row(question_id, perfect) {
    var english =  $("#"+question_id+"_en").html();
    var italian =  $("#"+question_id+"_it").html();
    var rowspan = "1";
    var stripe = $("#stripe_toggle").html();
    var row_id = "tr_"+question_id+"_js"; // <-"_js" will go away.
    if (perfect == true) {rowspan = 1;} else {rowspan = 2;}
    var english_td = "<td class='en' rowspan='" + rowspan + "'>" + english + "</td>";
    var evaluation = $("#"+row_id+"_eval").html();
    var correct_td = "";
    var eval_tr = "";
    if (perfect == true) {
        correct_td = "<td class='corr'> " + evaluation + "</td>";
        eval_tr = ""; // no correction necessary: user's response was correct.
    } else {
	if (evaluation == "") {
	    // user's response was blank: maybe they need encouragement by showing the correct response.
            correct_td = "<td class='corr'> " + italian + "</td>";
            eval_tr = "";
	} else {
            eval_tr = "<tr class='" + stripe + "'><td class='incorr'>" + evaluation + "</td></tr>";
            correct_td = "<td>" + italian + "</td>";
	}
    }

    var row
        = "<tr id='" + row_id + "' style='display:none' class='" + stripe + "'  >" +
        english_td +
        correct_td +
          "</tr>" +
          eval_tr;

    $("#quiz_table").prepend(row);

    $("#" + row_id ).fadeIn("fast");

    if (stripe == "odd") {
        $("#stripe_toggle").html("even");
    } else {
        $("#stripe_toggle").html("odd");
    }
}
