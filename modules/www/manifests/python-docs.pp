# Create a clone of python's docs on our website.

class www::python-docs ( $web_root_dir, $version ) {

  # Install python docs unless they're already there.
  # We use the name of the archive we're passed as part of the already-there
  # key so that they'll be updated if it changes.
  $archive_name = "python-$version-docs-html"
  $installed_key = "/usr/local/var/sr/python-docs-${$version}-installed"
  exec { 'install-python-docs':
    command =>
         "rm -rf ${web_root_dir}/docs/python ;\
          mkdir -p ${web_root_dir}/docs ;\
          curl http://docs.python.org/ftp/python/doc/${version}/$archive_name.tar.bz2 | tar -xj -C ${web_root_dir}/docs;\
          mv ${web_root_dir}/docs/$archive_name ${web_root_dir}/docs/python
          touch $installed_key",
    provider => 'shell',
    creates => $installed_key,
  }

}
