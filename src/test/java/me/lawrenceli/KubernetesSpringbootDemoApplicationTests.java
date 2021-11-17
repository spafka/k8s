package me.lawrenceli;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.stream.IntStream;

@SpringBootTest
class KubernetesSpringbootDemoApplicationTests {


    @Autowired
    StringRedisTemplate stringRedisTemplate;

    @Test
    void contextLoads() {

    }



    @Test
    public void loopSet(){

        IntStream.rangeClosed(1,1000).forEach(x->{
            stringRedisTemplate.opsForValue().set(x+"",x+"");
        });
    }

}
