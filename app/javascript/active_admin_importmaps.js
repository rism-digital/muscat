import edtf, { format, defaults, parse, Date, Interval } from "edtf";

//console.log(format("1234/1235"));

defaults.level = 3;

window.edtf = edtf;
window.edtf_format = format;