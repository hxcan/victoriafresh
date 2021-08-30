Gem::Specification.new do |s| 
    s.name = 'VictoriaFreSh'
    s.version = '2021.8.20'
    s.date = '2021-08-20'
    s.summary = "VictoriaFreSh"
    s.description = "Virtual file system."
    s.authors = ["Hxcan Cai"]
    s.email = 'caihuosheng@gmail.com'
    s.files = ["lib/victoriafresh.rb", "victoriafresh.example.rb"]
    s.homepage =
            'http://rubygems.org/gems/VictoriaFreSh'
    s.license = 'MIT'
    
    s.add_runtime_dependency 'hx_cbor', '>= 2021.8.20'
    s.add_runtime_dependency 'get_process_mem', '>= 0.2.7'
end
