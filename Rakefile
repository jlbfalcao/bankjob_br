
# task :default => [:test]

desc "Converte extrado do visa personalité para OFX"
task :visa do
  Dir.glob("visa/*.html") do |file|
    fn = File.basename(file).split(".")[0]
    puts file
    system "bankjob -i #{file} --scraper visa.rb --ofx ofx/#{fn}.ofx --debug"
  end  
end

desc "Converte extrado do amex personalité para OFX"
task :amex do
   Dir.glob("amex/*.html") do |file|
     fn = File.basename(file).split(".")[0]
     puts file
     system "bankjob -i #{file} --scraper amex.rb --ofx ofx/#{fn}.ofx --debug"
   end
end