var logging_level = INFO;

function toggle_expand(expand_this) {
    if (expand_this.style.height == "100px") {
	expand_this.style.height = "auto";
	expand_this.style.width = "auto";
	expand_this.style.overflow = "auto";
    } else {
	expand_this.style.height = "100px";
	expand_this.style.width = "200px";
	expand_this.style.overflow = "scroll";
    }
}

function edit_game_dialog(game_id) {
    $("#editgame"+game_id)[0].style.display = "block";
}

function edit_group_dialog(game_id) {
    $("#editgroup"+game_id)[0].style.display = "block";
}

