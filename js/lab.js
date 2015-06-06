var logging_level = INFO;

var cloud_speeds = {};

var wind_speed = 100;
var new_cloud_frequency = 10000;

var total_clouds = -1;
var oldest_cloud = 0;

var current_speed_limit = 5;

function start_lab() {
    log(INFO,"Hello, starting lab.");
    var i = 0;

    setInterval(function() {
	blow_clouds(oldest_cloud);
    },wind_speed);


    setInterval(function() {
	add_new_cloud();
    },new_cloud_frequency);


    log(INFO,"lab has started.");
}

function add_new_cloud() {
    total_clouds++;
    var i = total_clouds;
    var left_increment = Math.floor(Math.random()*50) - 25;
    var initial_left = 75 + left_increment;

    cloud_speeds["cloud_"+ i] =  Math.random()*0.010;
    log(INFO,"set cloud speed for: cloud_" + i + " is: " + cloud_speeds["cloud_"+i]);

    $("#giardino").append("<i id='cloud_" + i + "' class='fa fa-cloud diagonal motion' style='font-size:100px;left:" + initial_left+ "%;top:5%' >");


    log(INFO,"Added new cloud; total clouds: " + total_clouds + " ; oldest: " + oldest_cloud);
}

function blow_clouds(i) {
    log(DEBUG,"blow_clouds(" + i + ")");
    log(DEBUG,"total clouds: " + total_clouds);
    var cloud =  $("#cloud_"+i);
    if (cloud[0]) {
	blow_cloud(cloud[0]);
    } else {
	log(DEBUG,"cloud: " + i + " does not exist - maybe it got removed.");
    }

    if (i <= total_clouds) {
	blow_clouds(i+1);
    }
}

function blow_cloud(cloud) {
    var cloud_id = cloud.id;
    var re = /cloud_([^_]+)/;
    var bare_id = cloud_id.replace(re,"$1");

    if (cloud_speeds[cloud_id] == undefined) {
	log(INFO,"Cloud can't blow until it has a speed: " + cloud_speeds);
	return;
    } else {
	log(DEBUG,"Cloud# " + bare_id + " is ready to blow.");
    }

    log(DEBUG,"current cloud left: " + cloud.style.left);
    var cloud_left= parseFloat(cloud.style.left.replace('%',''));
    var cloud_top= parseFloat(cloud.style.top.replace('%',''));

    log(DEBUG,"new cloud left will be: " + (cloud_left + cloud_speeds[cloud_id])+"%");

    cloud.style.left = (cloud_left - cloud_speeds[cloud_id])+"%";
    cloud.style.top = (cloud_top + cloud_speeds[cloud_id])+"%";

    if (cloud_left < 0) {
	log(INFO,"Removing cloud..");

	log(INFO,"Looking for cloud with bare_id: " + bare_id);

	if (bare_id == oldest_cloud) {
	    log(INFO,"cloud# " + bare_id + " was the oldest cloud; incrementing oldest_cloud.");
	    oldest_cloud++;
	}

	$("#"+cloud.id).remove();
	return;
    }

    if (cloud_speeds[cloud_id] < 0) {
	cloud_speeds[cloud_id] = 0.1;
	return;
    }

    if (cloud_speeds[cloud_id] > 5) {
	cloud_speeds[cloud_id] = 5;
	return;
    }

    var incr = Math.floor(Math.random()*100);

    if (incr < 5) {
        cloud_speeds[cloud_id] = cloud_speeds[cloud_id] - 0.1;
	log(DEBUG,"cloud " + cloud_id + " slowed down to: " + cloud_speeds[cloud_id]);
    } else {
        if (incr < current_speed_limit) {
	    cloud_speeds[cloud_id] = cloud_speeds[cloud_id] + 0.5;
	    log(DEBUG,"cloud " + cloud_id + " sped up to: " + cloud_speeds[cloud_id]);
        }
    }
}

