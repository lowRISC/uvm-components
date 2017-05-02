// Author: Florian Zaruba, ETH Zurich
// Date: 02.05.2017
// Description: lsu configuration object
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

class lsu_env_config extends uvm_object;

    // UVM Factory Registration Macro
    `uvm_object_utils(lsu_env_config)

    // a functional unit master interface
    virtual mem_if m_mem_if;
    virtual lsu_if m_lsu_if;

    // an agent config
    mem_if_agent_config m_mem_if_agent_config;
    lsu_if_agent_config m_lsu_if_agent_config;

endclass : lsu_env_config
