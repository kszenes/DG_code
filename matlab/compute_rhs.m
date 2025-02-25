function [rhsu] = compute_rhs(u,r,n_qp_1D,mass,inv_mass,phi_val,phi_grad,phi_val_bd,hx,hy,wts,wts2d,d1,d2,fact_int,fact_bd,complem_fact,radius,pts2d_phi,pts2d_phi_bd,coriolis_fun,eq_type)
%compute rsh of the ode

%dimension: (cardinality)*(num_elems)*(num_eqns)
rhsu=zeros(size(u));

%cardinality and qp
dim=(max(r(:))+1)^2;
n_qp=n_qp_1D^2;

%determinants of the internal and boundary mappings: 1=bottom, 2=right, 3=top, 4=left
determ=hx*hy/4;
determ_int = radius*radius * fact_int;
bd_det(1)=hx/2; bd_det(2)=hy/2; bd_det(3)=hx/2; bd_det(4)=hy/2;

%compute solution in the quadrature points (sort of modal to nodal
%conversion)
u_qp=zeros(n_qp,size(u,2),size(u,3));
for i=1:size(u,3)
    u_qp(:,:,i)=reshape(phi_val{1}*reshape(u(:,:,i),dim*d1*d2,1),n_qp,d1*d2);
    %u_qp(:,:,i)=phi_val*u(:,:,i);
end

%INTERNAL INTEGRALS

%compute physical fluxes
[flux_fun_x, flux_fun_y]=flux_function(u_qp,eq_type,radius,pts2d_phi(1:n_qp,:),pts2d_phi(n_qp+1:2*n_qp,:), fact_int);    

%compute internal integral and add it to the rhs
%det_internal*inverse_of_jacobian_x_affine*sum(dPhi/dr*f_x*weights)+
% %det_internal*inverse_of_jacobian_y_affine*sum(dPhi/ds*f_y*weights)
for i=1:size(u,3)
    % === CORRECT ===
    rhsu(:,:,i)=reshape(phi_grad{1}'*reshape(flux_fun_x(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hx).*determ +...
        reshape(phi_grad{2}'*reshape(fact_int.*flux_fun_y(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hy).*determ;
%     
    % === DEBUG ====
%     rhsu(:,:,i)=reshape(phi_grad{1}'*reshape(flux_fun_x(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2);
%     rhsu(:,:,i)=rhsu(:,:,i)+reshape(phi_grad{2}'*reshape(fact_int.*flux_fun_y(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hy).*determ;
    % === END ===
    
%     rhsu(:,:,i)=reshape(phi_grad{1}'*reshape(flux_fun_x(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2) +...
%         reshape(phi_grad{2}'*reshape(fact_int.*flux_fun_y(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2);
    
%     rhsu(:,:,i)=reshape(phi_grad{1}'*reshape(determ_int.*flux_fun_x(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hx).*determ +...
%         reshape(phi_grad{2}'*reshape(determ_int.*fact_int.*flux_fun_y(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hy).*determ;
%     rhsu(:,:,i)=reshape(phi_grad{1}'*reshape(flux_fun_x(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hx)*determ +...
%         reshape(phi_grad{2}'*reshape(flux_fun_y(:,:,i).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*(2/hy)*determ;
    %rhsu(:,:,i)=phi_grad(:,:,1)'*(flux_fun_x(:,:,i).*wts2d)*(2/hx)*determ +...
        %phi_grad(:,:,2)'*(fact_int.*flux_fun_y(:,:,i).*wts2d)*(2/hy)*determ;
end

%BOUNDARY INTEGRALS

%compute solution in the boundary quadrature points (sort of modal to nodal
%conversion)
%dimension: (num_bd_qp)*(cardinality)*num_faces*num_equations
u_qp_bd=zeros(length(wts),size(u,2),4,size(u,3));
for n=1:size(u,3)
    for i=1:4
        u_qp_bd(:,:,i,n)=reshape(phi_val_bd{i}*reshape(u(:,:,n),dim*d1*d2,1),n_qp_1D,d1*d2);
        %u_qp_bd(:,:,i,n)=phi_val_bd(:,:,i)*u(:,:,n); 
    end
end

%compute LF fluxes
num_flux=compute_numerical_flux(u_qp_bd,d1,d2,fact_bd,eq_type,radius,pts2d_phi_bd(1:n_qp_1D,:,:),pts2d_phi_bd(n_qp_1D+1:2*n_qp_1D,:,:));

%compute boundary integrals and subtract them to the rhs
bd_term=zeros(size(u));
for n=1:size(u,3)
    for i=1:4
        %det_bd*sum(Phi*num_flux*weights)
        bd_term(:,:,n)=bd_term(:,:,n)+reshape(phi_val_bd{i}'*reshape(num_flux(:,:,i,n).*wts,n_qp_1D*d1*d2,1),dim,d1*d2).*bd_det(i);
        %bd_term(:,:,n)=bd_term(:,:,n)+phi_val_bd(:,:,i)'*(num_flux(:,:,i,n).*wts)*bd_det(i);
    end
    rhsu(:,:,n)=rhsu(:,:,n)-bd_term(:,:,n);
end

%add corrective internal term for the divergence, only in spherical
%coordinates for swe
if eq_type=="swe_sphere"
%     rhsu(:,:,2)=rhsu(:,:,2)+reshape(phi_val{1}'*reshape(complem_fact.*flux_fun_y(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,3)=rhsu(:,:,3)-reshape(phi_val{1}'*reshape(complem_fact.*flux_fun_x(:,:,2).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
    %rhsu(:,:,2)=rhsu(:,:,2)+phi_val'*(complem_fact.*flux_fun_y(:,:,2).*wts2d)*determ;
    %rhsu(:,:,3)=rhsu(:,:,3)-phi_val'*(complem_fact.*flux_fun_x(:,:,2).*wts2d)*determ;
end


g=9.80616;
% source term
if eq_type == "swe_sphere"
%     rhsu(:,:,3) = rhsu(:,:,3) + u_qp(:,:,3) .* u_qp(:,:,3) ./ u_qp(:,:,1) .* complem_fact;
%     rhsu(:,:,1)=rhsu(:,:,1) + reshape(phi_val{1}'*reshape(complem_fact./fact_int.*u_qp(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,2)=rhsu(:,:,2) + reshape(phi_val{1}'*reshape(complem_fact./fact_int.*u_qp(:,:,2).*u_qp(:,:,3)./u_qp(:,:,1).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,3)=rhsu(:,:,3) + reshape(phi_val{1}'*reshape(complem_fact./fact_int.*u_qp(:,:,3).*u_qp(:,:,3)./u_qp(:,:,1).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;

    rhsu(:,:,3)=rhsu(:,:,3) - reshape(phi_val{1}'*reshape(complem_fact*0.5*g.*u_qp(:,:,1).^2.*wts2d,n_qp*d1*d2,1),dim,d1*d2).*determ;
%     rhsu(:,:,3)=rhsu(:,:,3) - reshape(phi_val{1}'*reshape(determ_int.*complem_fact*0.5*g.*u_qp(:,:,1).^2.*wts2d,n_qp*d1*d2,1),dim,d1*d2).*determ;


%     rhsu(:,:,1)=rhsu(:,:,1) + reshape(phi_val{1}'*reshape(complem_fact.*u_qp(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,2)=rhsu(:,:,2) + reshape(phi_val{1}'*reshape(complem_fact.*u_qp(:,:,2).*u_qp(:,:,3)./u_qp(:,:,1).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,3)=rhsu(:,:,3) + reshape(phi_val{1}'*reshape(complem_fact.*u_qp(:,:,3).*u_qp(:,:,3)./u_qp(:,:,1).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
end

%add coriolis term to second and third equation of the swe
if eq_type=="swe" || eq_type=="swe_sphere"
    coriolis=coriolis_fun(pts2d_phi(1:n_qp,:),pts2d_phi(n_qp+1:2*n_qp,:));
%     rhsu(:,:,2)=rhsu(:,:,2)+radius*reshape(phi_val{1}'*reshape(complem_fact.*coriolis.*u_qp(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,3)=rhsu(:,:,3)-radius*reshape(phi_val{1}'*reshape(complem_fact.*coriolis.*u_qp(:,:,2).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
    
    rhsu(:,:,2)=rhsu(:,:,2)+radius*reshape(phi_val{1}'*reshape(coriolis.*fact_int.*u_qp(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2).*determ;
    rhsu(:,:,3)=rhsu(:,:,3)-radius*reshape(phi_val{1}'*reshape(coriolis.*fact_int.*u_qp(:,:,2).*wts2d,n_qp*d1*d2,1),dim,d1*d2).*determ;
    
    
%     rhsu(:,:,2)=rhsu(:,:,2)+radius*reshape(phi_val{1}'*reshape(fact_int.*coriolis.*u_qp(:,:,3).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     rhsu(:,:,3)=rhsu(:,:,3)-radius*reshape(phi_val{1}'*reshape(fact_int.*coriolis.*u_qp(:,:,2).*wts2d,n_qp*d1*d2,1),dim,d1*d2)*determ;
%     %rhsu(:,:,2)=rhsu(:,:,2)+radius*phi_val(:,:)'*(fact_int.*coriolis.*u_qp(:,:,3).*wts2d)*determ;
% 	%rhsu(:,:,3)=rhsu(:,:,3)-radius*phi_val(:,:)'*(fact_int.*coriolis.*u_qp(:,:,2).*wts2d)*determ;
end

%invert the (local) mass matrix and divide by radius
for n=1:size(u,3)
    rhsu(:,:,n)=1/radius*reshape(inv_mass*reshape(rhsu(:,:,n),dim*d1*d2,1),dim,d1*d2);
%     rhsu(:,:,n)=reshape(inv_mass*reshape(rhsu(:,:,n),dim*d1*d2,1),dim,d1*d2);

end


end