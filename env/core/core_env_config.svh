// Author: Florian Zaruba, ETH Zurich
// Date: 08.05.2017
// Description: core configuration object
//
// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
// Bug fixes and contributions will eventually be released under the
// SolderPad open hardware license in the context of the PULP platform
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
// University of Bologna.

class core_env_config extends uvm_object;

    // UVM Factory Registration Macro
    `uvm_object_utils(core_env_config)

    // a functional unit master interface
    virtual core_if m_core_if;
    virtual dcache_if m_dcache_if;

    // an agent config

    core_if_agent_config m_core_if_agent_config;
    dcache_if_agent_config m_dcache_if_agent_config;

endclass : core_env_config
