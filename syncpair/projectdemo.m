x1 = [1,3];
x2 = [8,9];
d = [2 8];

figure(1), clf;
axis equal
xlim([0 10]);
ylim([0 10]);
hold on
plot(x1(1),x1(2),'b.');
plot(x2(1),x2(2),'b.');
plot(d(1),d(2),'r.');
quiver(x1(1),x1(2),x2(1)-x1(1),x2(2)-x1(2),0,'b-');
quiver(x1(1),x1(2),d(1)-x1(1),d(2)-x1(2),0,'r-');

dist = dot(d-x1, x2-x1) / norm(x2-x1);
p = x1 + dot(d-x1, x2-x1)/norm(x2-x1)^2 * (x2-x1);

plot(p(1),p(2),'g.');

quiver(d(1),d(2),p(1)-d(1),p(2)-d(2),0,'g-');

