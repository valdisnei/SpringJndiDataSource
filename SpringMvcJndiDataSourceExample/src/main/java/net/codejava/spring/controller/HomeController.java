package net.codejava.spring.controller;

import java.io.IOException;
import java.util.List;

import javax.annotation.PostConstruct;

import net.codejava.spring.dao.UserDAO;
import net.codejava.spring.migration.MigrationService;
import net.codejava.spring.model.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
public class HomeController {

	@Autowired
	private UserDAO userDao;
	
	@Autowired
	private MigrationService migration;
	
	@RequestMapping(value="/")
	public ModelAndView home() throws IOException{
		List<User> listUsers = userDao.list();
		ModelAndView model = new ModelAndView("home");
		model.addObject("userList", listUsers);
		return model;
	}
	
	@PostConstruct
	public void inicializa() {
		System.out.println("inicializando");
		
		migration.migrate();

	}
}
