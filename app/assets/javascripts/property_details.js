
function mouseOver(d) {

  // select the property ID from the row table
  sid = parseInt(d.find("td")[1].innerText);
  highlight(d);

  // refresh the waterfall chart with the data for the selected property
  $.ajax({
    type: "GET",
    contentType: "application/json; charset=utf-8",
    url: '/properties/waterfall',
    data: { property_id:  sid},
    dataType: 'json',
    success: function (data) {
       draw(data.waterfall);
       cash_flows(data.cash_flow);
    },
    error: function (result) {
       error();
    }
  });
}

$(document).ready(function() {

   // handle property row mouseover
  $("#cap_rate_table tbody").on("click", "tr", function(event) {
      mouseOver($(this))
  });

  $("tr[class='property']:first").click();

});


function highlight(d) {
  $("tr.selected").removeClass("selected");
  d.addClass("selected");
  d.prependTo( $("table#cap_rate_table tbody") );
}
 

function cash_flows(data) {
  console.log(data)
  // empty the last table
  $("#cash_yield_table tbody").empty()
  $('#cash_yield_table tbody').append('<tr><td>Price</td><td>' + data.price.formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>Downpayment</td><td>' + (data.price - data.loan_amt).formatMoney(0) + '</td></tr>');

  $('#cash_yield_table tbody').append('<tr><td>Rent</td><td>' + data.rent.formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>Payment</td><td>' + data.pmt.formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>Taxes</td><td>' + data.taxes.formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>Insurance</td><td>' + data.insurance.formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>PITI</td><td>' + data.piti.formatMoney(0) + '</td></tr>');

  $('#cash_yield_table tbody').append('<tr><td>Net Cash Flow</td><td>' + (data.rent - data.piti).formatMoney(0) + '</td></tr>');
  $('#cash_yield_table tbody').append('<tr><td>Net Cash Yield</td><td>' + Math.round(data.cash_yield * 100)/100+ '%</td></tr>');

}
function draw(data) {

  //empty the last chart
  $("#waterfall").empty()

  var margin = {top: 20, right: 30, bottom: 30, left: 40},
      width = 660 - margin.left - margin.right,
      height = 300 - margin.top - margin.bottom,
      padding = 0.3;

  var x = d3.scale.ordinal()
      .rangeRoundBands([0, width], padding);

  var y = d3.scale.linear()
      .range([height, 0]);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom");

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left")
      .tickFormat(function(d) { return dollarFormatter(d); });

 // Transform data (i.e., finding cumulative values and total) for easier charting
  var cumulative = 0;
  for (var i = 0; i < data.length; i++) {
    data[i].start = cumulative;
    cumulative += data[i].value;
    data[i].end = cumulative;

    data[i].class = ( data[i].value >= 0 ) ? 'positive' : 'negative'
  }

  data.push({
    name: 'Total',
    end: cumulative,
    start: 0,
    class: 'total'
  });

  console.log(data)

  var chart = d3.select("#waterfall")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  x.domain(data.map(function(d) { return d.name; }));
  y.domain([0, d3.max(data, function(d) { return d.end; })]);

  chart.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

  chart.append("g")
      .attr("class", "y axis")
      .call(yAxis);

  var bar = chart.selectAll(".bar")
      .data(data)
    .enter().append("g")
      .attr("class", function(d) { return "bar " + d.class })
      .attr("transform", function(d) { return "translate(" + x(d.name) + ",0)"; });

  bar.append("rect")
      .attr("y", function(d) { return y( Math.max(d.start, d.end) ); })
      .attr("height", function(d) { return Math.abs( y(d.start) - y(d.end) ); })
      .attr("width", x.rangeBand());

  bar.append("text")
      .attr("x", x.rangeBand() / 2)
      .attr("y", function(d) { return y(d.end) + 5; })
      .attr("dy", function(d) { return ((d.class=='negative') ? '-' : '') + ".75em" })
      .text(function(d) { return dollarFormatter(d.end - d.start);});

  bar.filter(function(d) { return d.class != "total" }).append("line")
      .attr("class", "connector")
      .attr("x1", x.rangeBand() + 5 )
      .attr("y1", function(d) { return y(d.end) } )
      .attr("x2", x.rangeBand() / ( 1 - padding) - 5 )
      .attr("y2", function(d) { return y(d.end) } )



  function dollarFormatter(n) {
    return '$' + Math.round(n);
  }
    
}
 
function error() {
    console.log("error")
}

Number.prototype.formatMoney = function(c, d, t){
var n = this, 
    c = isNaN(c = Math.abs(c)) ? 2 : c, 
    d = d == undefined ? "." : d, 
    t = t == undefined ? "," : t, 
    s = n < 0 ? "-" : "", 
    i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "", 
    j = (j = i.length) > 3 ? j % 3 : 0;
   return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
 };