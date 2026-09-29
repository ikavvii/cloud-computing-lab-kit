import java.io.IOException;
import java.time.LocalDate;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/** CSV contract: date,temperature; ISO date, Celsius, no quoted fields.
 * Repeated dates use DAILY MAXIMUM; change the reducer if the exam specifies mean.
 */
public class Weather {
    public enum Rows { HEADER, INVALID, VALID }
    public static class WeatherMapper extends Mapper<LongWritable, Text, Text, DoubleWritable> {
        public void map(LongWritable offset, Text line, Context ctx) throws IOException, InterruptedException {
            String[] fields = line.toString().trim().split(",", -1);
            if (fields.length > 0 && fields[0].trim().equalsIgnoreCase("date")) {
                ctx.getCounter(Rows.HEADER).increment(1); return;
            }
            String date;
            double temperature;
            try {
                if (fields.length != 2) throw new IllegalArgumentException();
                date = LocalDate.parse(fields[0].trim()).toString();
                temperature = Double.parseDouble(fields[1].trim());
                if (!Double.isFinite(temperature)) throw new IllegalArgumentException();
            } catch (RuntimeException e) {
                ctx.getCounter(Rows.INVALID).increment(1); return;
            }
            ctx.write(new Text(date), new DoubleWritable(temperature));
            ctx.getCounter(Rows.VALID).increment(1);
        }
    }
    public static class WeatherReducer extends Reducer<Text, DoubleWritable, Text, Text> {
        public void reduce(Text date, Iterable<DoubleWritable> values, Context ctx) throws IOException, InterruptedException {
            double maximum = Double.NEGATIVE_INFINITY;
            for (DoubleWritable value : values) maximum = Math.max(maximum, value.get());
            double threshold = ctx.getConfiguration().getDouble("weather.threshold", 25.0);
            ctx.write(date, new Text(maximum + "\t" + (maximum >= threshold ? "Shiny Day" : "Cool Day")));
        }
    }
    public static void main(String[] args) throws Exception {
        if (args.length < 2 || args.length > 3) {
            System.err.println("Usage: Weather <input> <new-output-directory> [threshold=25]"); System.exit(2);
        }
        double threshold = args.length == 3 ? Double.parseDouble(args[2]) : 25.0;
        if (!Double.isFinite(threshold)) throw new IllegalArgumentException("Threshold must be finite");
        Configuration conf = new Configuration();
        conf.setDouble("weather.threshold", threshold);
        Job job = Job.getInstance(conf, "weather-daily-maximum-classification");
        job.setJarByClass(Weather.class);
        job.setMapperClass(WeatherMapper.class);
        job.setReducerClass(WeatherReducer.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(DoubleWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        job.setNumReduceTasks(1);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
