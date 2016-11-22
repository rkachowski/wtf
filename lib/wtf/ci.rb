class CI < Thor
  option :branch, desc: "branch this job will run upon", default: "master"
  option :package_id, desc: "id of the package to build",  required: true
  option :project_path, desc: "path where the unity project will be generated and built",  default:"unity3d/citest"
  desc "jenkinsfile", "generate a jenkinsfile for the ci"
  def jenkinsfile
    props = options.clone

    template_path = File.join(File.dirname(__FILE__), "templates","Jenkinsfile.erb")
    File.open("Jenkinsfile","w") { |f| f << ERB.new(File.open(template_path).read).result(binding) }
  end
end