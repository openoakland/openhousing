var logging_level = INFO;

var default_prefix = "";

var source_language_model = "small";
var target_language_model = "small";

/* This is the entry point that the Clojure server side code (e.g. editor.clj:(onload), verb.clj:(onload))
   puts in the onload="" to tell the client to use in its onload().
   It looks through the DOM and populates each node with what its contents should be. The initial nodes
   are all of the verbs supplied by verb.clj:(defn generation-table), which creates a <tr> for each verb, 
   along with the <tr>'s interior <td> skeleton that gen_per_verb() fleshes out. */
function gen_per_verb(prefix, source_language, target_language) {
    var verb_rows;

    if (prefix == undefined) {
	prefix = default_prefix;
	verb_rows = get_verb_rows_by_class();
    } else {
	verb_rows = get_verb_rows_by_prefix(prefix);
    }

    // now call gen_from_verb() for each verb row, which will fill in all of the <td>s.
    verb_rows.each(function() {
	var verb_dom_id = this.id;
	var verb = verb_dom_id;
	var re = new RegExp("^" + prefix);
	verb = verb.replace(re,"");
	    verb = verb.replace(/^verb_/,"");
	gen_from_verb(verb,prefix,source_language,target_language);
    });
}

function gen_per_verb_with_dropdown(prefix,source_dropdown,target_dropdown) {
    gen_per_verb(prefix,$("#"+source_dropdown).val(),$("#"+target_dropdown).val());
}

function gen_from_verb(verb,prefix,source_language,target_language) {
    log(INFO,"gen_from_verb(" + verb + "," + prefix + ");");

    var source_verb_spec = encodeURIComponent(JSON.stringify({"synsem": {"cat" : "verb",
									 "sem": {"pred": verb}}}));

    function lookup_in_source_language(content) {
	// 1. The server sent us the verb in the source language: parse the response into a JSON object.
	var evaluated = jQuery.parseJSON(content);
	var response = evaluated[source_language];
	$("#"+prefix+"source_verb_"+verb).html("<a href='/engine/lookup?lang=" + source_language + "&spec=" + source_verb_spec + "&debug=true'>" + response+ "</a>");
    }

    $.ajax({
	cache: false,
	dataType: "html",
	url: "/engine/lookup?lang=" + source_language + "&spec=" + source_verb_spec,
	success: lookup_in_source_language
    });

    // not sure why or if this is necessary..??
    var re = new RegExp("^" + prefix);
    verb = verb.replace(re,"");
    verb = verb.replace(/^verb_/,"");

    if ($("#"+prefix+"_tenses")) {
	log(INFO,"tense_info? " + $("#"+prefix+"_tenses").text());
    } else {
	log(WARN,"NO TENSE INFO FOR: " + prefix);
    }
    
    var tenses = $("#"+prefix+"_tenses").text().split(/[ ]+/);
    spec = sentence_with_tense_info(source_language,verb,tenses);
    var serialized_spec = encodeURIComponent(JSON.stringify(spec));

    $.ajax({
	cache: false,
	dataType: "html",
	url: "/engine/generate?lang=" + source_language + "&model=" + source_language_model + "&spec="+serialized_spec,
	success: generate_with_verb
    });

    function generate_with_verb(content) {
	// 1. The server sent us an example sentence: parse the response into a JSON object.
	var evaluated = jQuery.parseJSON(content);
	var response = evaluated[source_language];
	var spec = evaluated.spec;
	var pred = spec["synsem"]["sem"]["pred"];

	var semantics = evaluated.semantics;
	if (response == "") {
	    response = "<i class='fa fa-times-circle'> </i>";
	}

	var serialized_spec = encodeURIComponent(JSON.stringify({"synsem": {"sem": semantics}}));

	// 2. Now that we have the example sentence in the source language in the variable _response_: now, paste it in to the DOM tree in the right place:
	$("#"+prefix+"verb_"+verb).html("<a href='/engine/generate?" + 
					"spec=" + serialized_spec + 
					"&lang=" + source_language + 
					"&model=" + source_language_model + 
					"&debug=true" +
					"'>" + response + "</a>");

	// reload link:
	$("#"+prefix+"reload_"+verb).attr("onclick",
					  "javascript:refresh_row('" + verb + "','" + prefix + "','" + 
					  source_language + "','" + target_language + "');return false;");

	var infinitive_spec = {"synsem": {"cat": "verb",
					  "sem": {"pred": verb},
					  "infl": "infinitive"}};

	var serialized_infinitive_spec = encodeURIComponent(JSON.stringify(infinitive_spec));
	var lookup_target_language_url = "/engine/lookup?lang=" + target_language + "&spec=" + serialized_infinitive_spec;

	$.ajax({
	    cache: false,
	    dataType: "html",
	    url: lookup_target_language_url,
	    success: translate_from_semantics
	});

	function translate_from_semantics(content) {
	    evaluated = jQuery.parseJSON(content);
	    var response;
	    if (evaluated.response == "") {
		// could not translate: show a link with an error icon (fa-times-circle)
		response = "<i class='fa fa-times-circle'> </i>" + " </a>";
	    } else {
		response = evaluated[target_language];
	    }
	    $("#"+prefix+"target_verb_"+verb).html("<a href='" + lookup_target_language_url + "&debug=true'>" + response + "</a>");

	    var generate_target_language_url = "/engine/generate?lang="+ target_language + "&model=" + 
		target_language_model + "&spec=" + serialized_spec;

	    $.ajax({
		cache: false,
		dataType: "html",
		url: generate_target_language_url,
		success: function translate(content) {
		    var evaluated  = jQuery.parseJSON(content);
		    var response = evaluated[target_language];
		    if (response == "") {
			// could not generate anything: show a link with an error icon (fa-times-circle)
			response = "<i class='fa fa-times-circle'> </i>";
		    }
		    $("#"+prefix+"target_translation_"+pred).html("<a href='" + generate_target_language_url + "&debug=true'>" + response + "</a>");
		}
	    });
	}
    }
}

function refresh_row(verb,prefix,source_language,target_language) {
    $("#"+prefix+"verb_"+verb).html("<i class='fa fa-spinner fa-spin'> </i>");
    $("#"+prefix+"target_verb").html("<i class='fa fa-spinner fa-spin'> </i>");
    $("#"+prefix+"target_translation_"+verb).html("<i class='fa fa-spinner fa-spin'> </i>");
    gen_from_verb(verb,prefix,source_language,target_language);
}

function get_verb_rows_by_class() {
    return $(".gen_source");
}

function get_verb_rows_by_prefix(prefix) {
    return $('#'+"generation_list_"+prefix).find(".gen_source");
}

function sentence_with_tense_info(language,pred,tenses) {
    log(INFO, "sentences with tense_info: " + tenses);
    var tense = tenses[Math.floor(Math.random()*tenses.length)];

    log(INFO, "Use tense: " + tense);

    if (tense == "conditional") {
	if (language == "it") {
	    return italian_conditional(pred);
	}
	if (language == "en") {
	    return english_conditional(pred);
	}
    }

    if (tense == "future") {
	if (language == "it") {
	    return italian_future(pred);
	}
	if (language == "en") {
	    return english_future(pred);
	}
    }

    if (tense == "futuro") {
	if (language == "it") {
	    return italian_future(pred);
	}
	if (language == "en") {
	    return english_future(pred);
	}
    }

    if (tense == "imperfect") {
	if (language == "it") {
	    return italian_imperfect(pred);
	}
	if (language == "en") {
	    return english_imperfect(pred);
	}
    }

    if (tense == "imperfetto") {
	if (language == "it") {
	    return italian_imperfect(pred);
	}
	if (language == "en") {
	    return english_imperfect(pred);
	}
    }

    if (tense == "passato") {
	if (language == "it") {
	    return italian_passato(pred);
	}
	if (language == "en") {
	    return english_passato(pred);
	}
    }

    if (tense == "present") {
	if (language == "it") {
	    return italian_present(pred);
	}
	if (language == "en") {
	    return english_present(pred);
	}
    }

    log(ERROR,"don't know what to do with sentence_with_tense_info(language=" + language + ",pred=" + pred + ",tenses=" + tenses + ")");
    log(ERROR,"  chosen tense: " + tense);
    return undefined;
}

// TODO: move to language-specific Javascript (or better, ClojureScript).

function italian_conditional(pred) {
    return {"synsem": {
	"sem": {
	    "tense": "conditional",    
	    "pred": pred}}};
};

function english_conditional(pred) {
    // italian and english are the same for future tense, so simply use one for the other.
    return italian_conditional(pred);
};

function italian_future(pred) {
    return {"synsem": {
	"sem": {
	    "tense": "futuro",    
	    "pred": pred}}};
};

function english_future(pred) {
    // italian and english are the same for future tense, so simply use one for the other.
    return italian_future(pred);
};

function italian_imperfect(pred) {
    return {"synsem": {"infl" : "imperfetto",
		       "sem" : { "pred" : pred }}}; 
	
};

function english_imperfect(pred) {
    // italian and english are the same for imperfect, so simply use one for the other.
    return italian_imperfect(pred);
};

function italian_present(pred) {
    return {"synsem": {
	"infl": "present",
	"sem": {
	    "tense": "present",    
	    "pred": pred}}};
};

function english_present(pred) {
    // italian and english are the same for present tense, so simply use one for the other.
    return italian_present(pred);
};

function italian_passato(pred) {
    return {"synsem": {
	"infl": "present",
	"sem": {
	    "aspect": "perfect",
	    "tense": "past",    
	    "pred": pred}}};
}

function english_passato(pred) {
    return {"synsem": {
	"sem": {
	    "aspect": "perfect",
	    "tense": "past",    
	    "pred": pred}}};
}

