function search() {
    $("#searchresults").html("");

    var search_exp = $("#search").val();
    $.ajax({
        dataType: "html",
        url: "/italian/search/q/?attrs=italian+english&search="+search_exp,
        success: function (content) {
            $("#searchresults").prepend(content);
            $("#search").focus();
        }
    });
}

